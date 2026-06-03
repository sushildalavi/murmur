import Foundation

public struct MemoInsights: Codable, Equatable, Hashable, Sendable {
    public var summary: String
    public var actionItems: [String]
    public var keywords: [String]

    public init(summary: String = "", actionItems: [String] = [], keywords: [String] = []) {
        self.summary = summary
        self.actionItems = actionItems
        self.keywords = keywords
    }

    public var isEmpty: Bool {
        summary.isEmpty && actionItems.isEmpty && keywords.isEmpty
    }
}
