import Foundation

#if canImport(AppIntents)
import AppIntents

public struct CreateActionItemIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Create Action Items"

    @Parameter(title: "Transcript")
    public var transcript: String

    public init() {
        transcript = ""
    }

    public init(transcript: String) {
        self.transcript = transcript
    }

    public func perform() async throws -> some IntentResult {
        .result()
    }

    public func actionItems(using summarizer: Summarizer = Summarizer()) -> [String] {
        let segments = transcript
            .split(whereSeparator: { ".!?".contains($0) })
            .enumerated()
            .map { index, sentence in
                TranscriptSegment(text: String(sentence), startTime: Double(index), endTime: Double(index + 1))
            }
        return summarizer.summarize(segments).actionItems
    }
}
#else
public struct CreateActionItemIntent: Sendable {
    public var transcript: String

    public init(transcript: String = "") {
        self.transcript = transcript
    }

    public func actionItems(using summarizer: Summarizer = Summarizer()) -> [String] {
        let segments = transcript
            .split(whereSeparator: { ".!?".contains($0) })
            .enumerated()
            .map { index, sentence in
                TranscriptSegment(text: String(sentence), startTime: Double(index), endTime: Double(index + 1))
            }
        return summarizer.summarize(segments).actionItems
    }
}
#endif
