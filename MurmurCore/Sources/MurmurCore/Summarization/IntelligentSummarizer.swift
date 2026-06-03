import Foundation
#if !os(watchOS) && canImport(FoundationModels)
import FoundationModels
#endif

/// Generates a memo's summary, action items, and topics.
///
/// When the device supports Apple Intelligence (iOS 26 / macOS 26 with the model
/// available), this runs Apple's on-device foundation model through the
/// `FoundationModels` framework, using guided generation to get structured
/// output directly. Everywhere else — older OSes, watchOS, Apple Intelligence
/// disabled, or any model error — it falls back to the deterministic heuristic
/// ``Summarizer`` so the feature degrades gracefully instead of disappearing.
public struct IntelligentSummarizer: Sendable {
    /// Whether on-device generation can run right now, with a reason when not.
    public enum Status: Equatable, Sendable {
        case available
        case unavailable(reason: String)
    }

    private let fallback = Summarizer()

    public init() {}

    public func status() -> Status {
        #if !os(watchOS) && canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(let reason):
                return .unavailable(reason: Self.describe(reason))
            }
        }
        #endif
        return .unavailable(reason: "Requires iOS 26 or macOS 26 with Apple Intelligence.")
    }

    /// Produces insights, preferring the on-device model and falling back to the
    /// heuristic summarizer.
    public func summarize(_ segments: [TranscriptSegment]) async -> MemoInsights {
        let transcript = segments
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return MemoInsights() }

        #if !os(watchOS) && canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *),
           case .available = SystemLanguageModel.default.availability,
           let generated = try? await Self.generateOnDevice(transcript: transcript) {
            return generated
        }
        #endif

        return fallback.summarize(segments)
    }
}

#if !os(watchOS) && canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Insights extracted from a personal voice memo transcript")
private struct GeneratedInsight {
    @Guide(description: "A faithful one or two sentence summary of the memo")
    var summary: String

    @Guide(description: "Action items or follow-ups explicitly mentioned, each a short imperative phrase; empty if there are none")
    var actionItems: [String]

    @Guide(description: "Up to five short topic keywords describing the memo")
    var topics: [String]
}

extension IntelligentSummarizer {
    @available(iOS 26.0, macOS 26.0, *)
    fileprivate static func generateOnDevice(transcript: String) async throws -> MemoInsights {
        let session = LanguageModelSession(
            instructions: """
            You summarize a person's private voice memos. Be concise and faithful \
            to the transcript. Never invent details that are not present.
            """
        )
        let response = try await session.respond(
            to: "Summarize this voice memo, then list any action items and topics.\n\nTranscript:\n\(transcript)",
            generating: GeneratedInsight.self
        )
        let insight = response.content
        return MemoInsights(
            summary: insight.summary,
            actionItems: insight.actionItems,
            keywords: insight.topics
        )
    }

    @available(iOS 26.0, macOS 26.0, *)
    fileprivate static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to generate insights."
        case .modelNotReady:
            return "The on-device model is still preparing. Try again shortly."
        @unknown default:
            return "Apple Intelligence is currently unavailable."
        }
    }
}

#endif
