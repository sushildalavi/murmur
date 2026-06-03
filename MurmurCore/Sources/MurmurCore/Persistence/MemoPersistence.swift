import Foundation

/// Durable storage for memos.
///
/// The app's observable `MemoStore` keeps an in-memory copy for SwiftUI, but the
/// source of truth lives behind this protocol so the persistence layer can be
/// swapped (SQLite on device, an in-memory fake in tests) without touching the
/// UI or view models.
public protocol MemoPersistence: AnyObject {
    /// All stored memos, newest update first.
    func load() throws -> [Memo]
    /// Inserts a new memo or replaces the existing one with the same id.
    func save(_ memo: Memo) throws
    /// Removes a single memo by id. No-op if it does not exist.
    func delete(id: UUID) throws
    /// Removes every memo.
    func deleteAll() throws
    /// Full-text search over titles and transcripts, ranked by relevance.
    /// An empty query returns everything, newest update first.
    func search(_ query: String) throws -> [Memo]
    /// Lightweight storage statistics for the privacy/metrics surfaces.
    func stats() throws -> StoreStats
}

/// Cheap, privacy-safe storage facts (counts and bytes only — never content).
public struct StoreStats: Equatable, Sendable {
    public var memoCount: Int
    public var databaseByteSize: Int64

    public init(memoCount: Int, databaseByteSize: Int64) {
        self.memoCount = memoCount
        self.databaseByteSize = databaseByteSize
    }
}
