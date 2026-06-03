import Foundation

public struct Summarizer {
    private let stopWords: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
        "in", "is", "it", "of", "on", "or", "that", "the", "to", "was",
        "were", "with", "you", "i", "we", "they", "this", "these", "those"
    ]

    public init() {}

    public func summarize(_ segments: [TranscriptSegment]) -> MemoInsights {
        let transcriptText = segments.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcriptText.isEmpty else {
            return MemoInsights()
        }

        let sentences = transcriptText
            .split(whereSeparator: { ".!?".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let summary = sentences.first ?? String(transcriptText.prefix(180))
        let actionItems = extractActionItems(from: sentences)
        let keywords = topKeywords(in: transcriptText)

        return MemoInsights(summary: summary, actionItems: actionItems, keywords: keywords)
    }

    public func makeTitle(from segments: [TranscriptSegment]) -> String {
        guard let firstText = segments.first?.text.trimmingCharacters(in: .whitespacesAndNewlines), !firstText.isEmpty else {
            return "New Memo"
        }
        return String(firstText.prefix(60))
    }

    private func extractActionItems(from sentences: [String]) -> [String] {
        let triggerWords = ["action:", "todo:", "todo", "follow up", "follow-up", "next step", "needs to", "need to", "should", "must"]
        return sentences.compactMap { sentence in
            let lowercased = sentence.lowercased()
            guard triggerWords.contains(where: { lowercased.contains($0) }) else { return nil }
            return sentence
        }
    }

    private func topKeywords(in text: String) -> [String] {
        var counts: [String: Int] = [:]
        let tokens = text
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty && !stopWords.contains($0) }

        for token in tokens {
            counts[token, default: 0] += 1
        }

        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(5)
            .map(\.key)
    }
}
