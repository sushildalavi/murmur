import Foundation

public struct SearchMemosIntent: Sendable {
    public var query: String

    public init(query: String) {
        self.query = query
    }

    public func results(from memos: [Memo], ranker: MemoRanker = MemoRanker()) -> [Memo] {
        ranker.rank(memos, query: query)
    }
}
