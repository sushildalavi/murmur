import Foundation

/// Ranks memos by semantic similarity to a query using on-device embeddings.
///
/// Memo vectors are cached by id + `updatedAt`, so re-querying an unchanged
/// library is cheap and edits transparently invalidate just that memo.
public final class SemanticMemoIndex: @unchecked Sendable {
    public struct ScoredMemo: Equatable, Sendable {
        public let memo: Memo
        public let score: Double
    }

    private let embeddings: EmbeddingService
    private let lock = NSLock()
    private var cache: [UUID: (updatedAt: Date, vector: [Double])] = [:]

    public init(embeddings: EmbeddingService = EmbeddingService()) {
        self.embeddings = embeddings
    }

    public var isAvailable: Bool { embeddings.isAvailable }

    /// Returns memos ranked by descending similarity to `query`, keeping only
    /// those above `threshold`. Empty if embeddings are unavailable or the query
    /// is blank.
    public func search(_ query: String, in memos: [Memo], limit: Int = 20, threshold: Double = 0.0) -> [ScoredMemo] {
        guard let queryVector = embeddings.vector(for: query) else { return [] }
        let scored = memos.compactMap { memo -> ScoredMemo? in
            guard let vector = vector(for: memo) else { return nil }
            return ScoredMemo(memo: memo, score: EmbeddingService.cosineSimilarity(queryVector, vector))
        }
        return scored
            .filter { $0.score > threshold }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    /// Convenience returning just the memos, most relevant first.
    public func rankedMemos(_ query: String, in memos: [Memo], limit: Int = 20, threshold: Double = 0.0) -> [Memo] {
        search(query, in: memos, limit: limit, threshold: threshold).map(\.memo)
    }

    private func vector(for memo: Memo) -> [Double]? {
        lock.lock()
        if let cached = cache[memo.id], cached.updatedAt == memo.updatedAt {
            lock.unlock()
            return cached.vector
        }
        lock.unlock()

        guard let vector = embeddings.vector(for: Self.embeddingText(for: memo)) else { return nil }

        lock.lock()
        cache[memo.id] = (memo.updatedAt, vector)
        lock.unlock()
        return vector
    }

    private static func embeddingText(for memo: Memo) -> String {
        [memo.title, memo.transcriptText]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }
}
