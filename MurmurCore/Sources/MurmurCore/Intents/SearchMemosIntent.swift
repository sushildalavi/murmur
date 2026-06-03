import Foundation

#if canImport(AppIntents)
import AppIntents

public struct SearchMemosIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Search Memos"

    @Parameter(title: "Query")
    public var query: String

    public init() {
        query = ""
    }

    public init(query: String) {
        self.query = query
    }

    public func perform() async throws -> some IntentResult {
        .result()
    }

    public func results(from memos: [Memo], ranker: MemoRanker = MemoRanker()) -> [Memo] {
        ranker.rank(memos, query: query)
    }
}
#else
public struct SearchMemosIntent: Sendable {
    public var query: String

    public init(query: String = "") {
        self.query = query
    }

    public func results(from memos: [Memo], ranker: MemoRanker = MemoRanker()) -> [Memo] {
        ranker.rank(memos, query: query)
    }
}
#endif
