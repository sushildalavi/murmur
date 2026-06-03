import Foundation

#if canImport(AppIntents)
import AppIntents

public struct CreateActionItemIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Create Action Items"
    public static var description = IntentDescription("Extract action items from a transcript.")

    @Parameter(title: "Transcript")
    public var transcript: String

    public init() {
        transcript = ""
    }

    public init(transcript: String) {
        self.transcript = transcript
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[String]> {
        let items = actionItems()
        let dialog: IntentDialog = items.isEmpty
            ? "No action items found."
            : "Found \(items.count) action item\(items.count == 1 ? "" : "s")."
        return .result(value: items, dialog: dialog)
    }

    public func actionItems(using summarizer: Summarizer = Summarizer()) -> [String] {
        // Pass the transcript as one segment so the summarizer splits on real
        // sentence boundaries (the periods stay intact).
        let segment = TranscriptSegment(text: transcript, startTime: 0, endTime: 0)
        return summarizer.summarize([segment]).actionItems
    }
}
#else
public struct CreateActionItemIntent: Sendable {
    public var transcript: String

    public init(transcript: String = "") {
        self.transcript = transcript
    }

    public func actionItems(using summarizer: Summarizer = Summarizer()) -> [String] {
        // Pass the transcript as one segment so the summarizer splits on real
        // sentence boundaries (the periods stay intact).
        let segment = TranscriptSegment(text: transcript, startTime: 0, endTime: 0)
        return summarizer.summarize([segment]).actionItems
    }
}
#endif
