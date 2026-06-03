import Foundation

public struct MemoSearchIndex {
    private var memosByID: [UUID: Memo] = [:]
    private var tokensByMemoID: [UUID: Set<String>] = [:]

    public init() {}

    public mutating func upsert(_ memo: Memo) {
        memosByID[memo.id] = memo
        tokensByMemoID[memo.id] = Self.tokens(in: memo)
    }

    public mutating func remove(id: UUID) {
        memosByID.removeValue(forKey: id)
        tokensByMemoID.removeValue(forKey: id)
    }

    public func search(_ query: String, ranker: MemoRanker = MemoRanker()) -> [Memo] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return memosByID.values.sorted { $0.updatedAt > $1.updatedAt }
        }

        let queryTokens = Self.tokens(in: trimmed)
        let matchingMemos = memosByID.values.filter { memo in
            let memoTokens = tokensByMemoID[memo.id] ?? []
            return queryTokens.contains(where: memoTokens.contains) ||
                memo.title.localizedCaseInsensitiveContains(trimmed) ||
                memo.transcriptText.localizedCaseInsensitiveContains(trimmed)
        }

        return ranker.rank(matchingMemos, query: trimmed)
    }

    public var allMemos: [Memo] {
        memosByID.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func tokens(in memo: Memo) -> Set<String> {
        tokens(in: [memo.title, memo.transcriptText].joined(separator: " "))
    }

    private static func tokens(in text: String) -> Set<String> {
        Set(
            text
                .lowercased()
                .split { !$0.isLetter && !$0.isNumber }
                .map(String.init)
                .filter { !$0.isEmpty }
        )
    }
}
