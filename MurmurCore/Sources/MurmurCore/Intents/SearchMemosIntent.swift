import Foundation

#if canImport(AppIntents)
import AppIntents

public struct SearchMemosIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Search Memos"
    public static var description = IntentDescription("Search your voice memos by title or transcript.")

    @Parameter(title: "Query")
    public var query: String

    public init() {
        query = ""
    }

    public init(query: String) {
        self.query = query
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[String]> {
        let memos = await MainActor.run { MemoStore.shared.memos }
        let titles = results(from: memos).prefix(5).map(\.title)
        let dialog: IntentDialog = titles.isEmpty
            ? "No memos matched “\(query)”."
            : "Found \(titles.count): \(titles.joined(separator: ", "))."
        return .result(value: Array(titles), dialog: dialog)
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
