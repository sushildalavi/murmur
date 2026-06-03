import Foundation
import Observation

/// The observable, in-memory view of the memo library that SwiftUI binds to.
///
/// Durability is delegated to an optional ``MemoPersistence``. When one is
/// present (the live app uses ``SQLiteMemoStore``), memos are loaded on launch
/// and every mutation is written through. With no persistence the store is a
/// fast in-memory cache, which keeps unit tests hermetic.
@MainActor
@Observable
public final class MemoStore {
    public static let shared = MemoStore(persistence: try? SQLiteMemoStore.makeDefault())

    public private(set) var memos: [Memo] = []

    @ObservationIgnored private let persistence: (any MemoPersistence)?

    public init(memos: [Memo] = [], persistence: (any MemoPersistence)? = nil) {
        self.persistence = persistence
        if let persistence, let loaded = try? persistence.load() {
            self.memos = loaded
        } else {
            self.memos = memos
        }
    }

    public func upsert(_ memo: Memo) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index] = memo
        } else {
            memos.insert(memo, at: 0)
        }
        try? persistence?.save(memo)
    }

    public func memo(id: UUID) -> Memo? {
        memos.first { $0.id == id }
    }

    public func remove(id: UUID) {
        memos.removeAll { $0.id == id }
        try? persistence?.delete(id: id)
    }

    public func removeAll() {
        memos.removeAll()
        try? persistence?.deleteAll()
    }

    /// Ranked full-text search. Uses the persistent FTS index when available and
    /// falls back to the in-memory ranking index otherwise.
    public func search(_ query: String) -> [Memo] {
        if let persistence, let results = try? persistence.search(query) {
            return results
        }
        var index = MemoSearchIndex()
        for memo in memos { index.upsert(memo) }
        return index.search(query)
    }

    public func metrics(calendar: Calendar = .current) -> MemoMetrics {
        MemoMetrics.calculate(from: memos, calendar: calendar)
    }
}
