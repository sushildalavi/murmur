import Foundation

#if canImport(AppIntents)
import AppIntents

public struct SummarizeLatestMemoIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Summarize Latest Memo"
    public static var description = IntentDescription("Summarize the most recently updated memo on device.")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        guard let summary = await summary() else {
            return .result(value: "", dialog: "No memos available yet.")
        }
        return .result(value: summary.text, dialog: summary.dialog)
    }

    public func summary(using summarizer: IntelligentSummarizer = IntelligentSummarizer()) async -> (text: String, dialog: IntentDialog)? {
        let memo = await MainActor.run { MemoStore.shared.memos.first }
        guard let memo else { return nil }
        let insights = await summarizer.summarize(memo.transcriptSegments)
        let text = insights.summary.isEmpty ? "No summary available." : insights.summary
        return (text: text, dialog: "Summarized “\(memo.title)”.")
    }
}
#else
public struct SummarizeLatestMemoIntent: Sendable {
    public init() {}
}
#endif
