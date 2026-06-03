import Foundation

public struct CreateActionItemIntent: Sendable {
    public var memo: Memo

    public init(memo: Memo) {
        self.memo = memo
    }

    public func actionItems(using summarizer: Summarizer = Summarizer()) -> [String] {
        summarizer.summarize(memo.transcriptSegments).actionItems
    }
}
