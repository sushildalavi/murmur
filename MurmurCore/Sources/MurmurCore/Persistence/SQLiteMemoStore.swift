import Foundation
import SQLite3

/// On-device persistence backed by the system SQLite, with an FTS5 index for
/// full-text search over titles and transcripts.
///
/// Design notes:
/// - Uses the system `sqlite3` C API directly — no third-party dependency.
/// - WAL journaling with a busy timeout and an in-memory temp store.
/// - Memo rows store structured fields plus the transcript as JSON; the FTS5
///   virtual table holds only the searchable text, keyed by memo id.
/// - All access is serialized on a private queue, so instances are safe to share
///   across tasks. SQLite's own handle is opened in full-mutex mode as a second
///   line of defense.
public final class SQLiteMemoStore: MemoPersistence, @unchecked Sendable {
    public enum StoreError: Error {
        case open(String)
        case prepare(String)
        case step(String)
        case decodeTranscript
    }

    private let db: OpaquePointer
    private let path: String
    private let queue = DispatchQueue(label: "com.sushildalavi.murmur.sqlite")

    // SQLite wants this sentinel so it copies bound strings rather than holding
    // a pointer into Swift-owned memory that may be freed.
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    public init(path: String) throws {
        self.path = path
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            if let handle { sqlite3_close(handle) }
            throw StoreError.open(message)
        }
        self.db = handle
        try configure()
        try migrate()
    }

    deinit {
        sqlite3_close(db)
    }

    /// The default on-device store location under Application Support.
    public static func makeDefault() throws -> SQLiteMemoStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("Murmur", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try SQLiteMemoStore(path: directory.appendingPathComponent("memos.sqlite").path)
    }

    // MARK: - Setup

    private func configure() throws {
        try exec("PRAGMA journal_mode = WAL;")
        try exec("PRAGMA synchronous = NORMAL;")
        try exec("PRAGMA busy_timeout = 3000;")
        try exec("PRAGMA temp_store = MEMORY;")
        try exec("PRAGMA foreign_keys = ON;")
    }

    private func migrate() throws {
        try exec("""
        CREATE TABLE IF NOT EXISTS memos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            audio_url TEXT NOT NULL,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            transcript_json TEXT NOT NULL
        );
        """)
        try exec("""
        CREATE VIRTUAL TABLE IF NOT EXISTS memo_fts USING fts5(
            memo_id UNINDEXED,
            title,
            body,
            tokenize = 'unicode61'
        );
        """)
        try exec("CREATE INDEX IF NOT EXISTS idx_memos_updated ON memos(updated_at DESC);")
    }

    // MARK: - MemoPersistence

    public func load() throws -> [Memo] {
        try queue.sync {
            try fetchMemos(
                sql: "SELECT id, title, audio_url, created_at, updated_at, transcript_json FROM memos ORDER BY updated_at DESC;",
                bind: { _ in }
            )
        }
    }

    public func save(_ memo: Memo) throws {
        try queue.sync {
            try exec("BEGIN IMMEDIATE TRANSACTION;")
            do {
                let transcript = try Self.encodeTranscript(memo.transcriptSegments)
                try run(
                    "INSERT OR REPLACE INTO memos (id, title, audio_url, created_at, updated_at, transcript_json) VALUES (?, ?, ?, ?, ?, ?);",
                    bind: { stmt in
                        sqlite3_bind_text(stmt, 1, memo.id.uuidString, -1, Self.transient)
                        sqlite3_bind_text(stmt, 2, memo.title, -1, Self.transient)
                        sqlite3_bind_text(stmt, 3, memo.audioFileURL.absoluteString, -1, Self.transient)
                        sqlite3_bind_double(stmt, 4, memo.createdAt.timeIntervalSince1970)
                        sqlite3_bind_double(stmt, 5, memo.updatedAt.timeIntervalSince1970)
                        sqlite3_bind_text(stmt, 6, transcript, -1, Self.transient)
                    }
                )
                try run("DELETE FROM memo_fts WHERE memo_id = ?;", bind: { stmt in
                    sqlite3_bind_text(stmt, 1, memo.id.uuidString, -1, Self.transient)
                })
                try run(
                    "INSERT INTO memo_fts (memo_id, title, body) VALUES (?, ?, ?);",
                    bind: { stmt in
                        sqlite3_bind_text(stmt, 1, memo.id.uuidString, -1, Self.transient)
                        sqlite3_bind_text(stmt, 2, memo.title, -1, Self.transient)
                        sqlite3_bind_text(stmt, 3, memo.transcriptText, -1, Self.transient)
                    }
                )
                try exec("COMMIT;")
            } catch {
                try? exec("ROLLBACK;")
                throw error
            }
        }
    }

    public func delete(id: UUID) throws {
        try queue.sync {
            try run("DELETE FROM memos WHERE id = ?;", bind: { stmt in
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, Self.transient)
            })
            try run("DELETE FROM memo_fts WHERE memo_id = ?;", bind: { stmt in
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, Self.transient)
            })
        }
    }

    public func deleteAll() throws {
        try queue.sync {
            try exec("DELETE FROM memos;")
            try exec("DELETE FROM memo_fts;")
        }
    }

    public func search(_ query: String) throws -> [Memo] {
        guard let match = Self.ftsQuery(for: query) else {
            return try load()
        }
        return try queue.sync {
            try fetchMemos(
                sql: """
                SELECT m.id, m.title, m.audio_url, m.created_at, m.updated_at, m.transcript_json
                FROM memo_fts
                JOIN memos m ON m.id = memo_fts.memo_id
                WHERE memo_fts MATCH ?
                ORDER BY bm25(memo_fts);
                """,
                bind: { stmt in
                    sqlite3_bind_text(stmt, 1, match, -1, Self.transient)
                }
            )
        }
    }

    public func stats() throws -> StoreStats {
        try queue.sync {
            var count = 0
            try run("SELECT COUNT(*) FROM memos;", bind: { _ in }, step: { stmt in
                count = Int(sqlite3_column_int(stmt, 0))
            })
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            let size = (attributes?[.size] as? Int64) ?? 0
            return StoreStats(memoCount: count, databaseByteSize: size)
        }
    }

    // MARK: - FTS query construction

    /// Builds an injection-safe FTS5 MATCH expression: each query token is
    /// reduced to letters/digits and turned into a prefix term, then AND-ed.
    /// Returns nil for an empty query so callers fall back to "return all".
    static func ftsQuery(for query: String) -> String? {
        let terms = query
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !terms.isEmpty else { return nil }
        return terms.map { "\($0)*" }.joined(separator: " AND ")
    }

    // MARK: - Row helpers

    private func fetchMemos(sql: String, bind: (OpaquePointer) -> Void) throws -> [Memo] {
        var memos: [Memo] = []
        try run(sql, bind: bind, step: { stmt in
            if let memo = try Self.decodeRow(stmt) {
                memos.append(memo)
            }
        })
        return memos
    }

    private static func decodeRow(_ stmt: OpaquePointer) throws -> Memo? {
        guard
            let idText = sqlite3_column_text(stmt, 0),
            let id = UUID(uuidString: String(cString: idText)),
            let titleText = sqlite3_column_text(stmt, 1),
            let urlText = sqlite3_column_text(stmt, 2),
            let url = URL(string: String(cString: urlText)),
            let transcriptText = sqlite3_column_text(stmt, 5)
        else {
            return nil
        }
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
        let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
        let segments = try decodeTranscript(String(cString: transcriptText))
        return Memo(
            id: id,
            title: String(cString: titleText),
            audioFileURL: url,
            createdAt: createdAt,
            updatedAt: updatedAt,
            transcriptSegments: segments
        )
    }

    private static func encodeTranscript(_ segments: [TranscriptSegment]) throws -> String {
        let data = try JSONEncoder().encode(segments)
        return String(decoding: data, as: UTF8.self)
    }

    private static func decodeTranscript(_ json: String) throws -> [TranscriptSegment] {
        guard let data = json.data(using: .utf8) else { throw StoreError.decodeTranscript }
        return try JSONDecoder().decode([TranscriptSegment].self, from: data)
    }

    // MARK: - Low-level execution

    private func exec(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(error)
            throw StoreError.step(message)
        }
    }

    /// Prepares a statement, binds, and steps it to completion. If `step` is
    /// provided it is called for every returned row.
    private func run(
        _ sql: String,
        bind: (OpaquePointer) -> Void,
        step: ((OpaquePointer) throws -> Void)? = nil
    ) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            throw StoreError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        bind(stmt)

        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                try step?(stmt)
            } else if result == SQLITE_DONE {
                break
            } else {
                throw StoreError.step(String(cString: sqlite3_errmsg(db)))
            }
        }
    }
}
