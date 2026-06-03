import Foundation

#if canImport(AppIntents)
import AppIntents

public struct ExtractActionItemsIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Extract Action Items"
    public static var description = IntentDescription("Extract action items from your latest voice memo.")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[String]> {
        let items = await actionItems()
        let dialog: IntentDialog
        if items.isEmpty {
            dialog = "No action items found."
        } else {
            dialog = "Found \(items.count) action item\(items.count == 1 ? "" : "s")."
        }
        return .result(value: items, dialog: dialog)
    }

    public func actionItems(using summarizer: Summarizer = Summarizer()) async -> [String] {
        let memo = await MainActor.run { MemoStore.shared.memos.first }
        guard let memo else { return [] }
        return summarizer.summarize(memo.transcriptSegments).actionItems
    }
}
#else
public struct ExtractActionItemsIntent: Sendable {
    public init() {}
}
#endif
