import Foundation

public struct MemoRanker {
    public init() {}

    public func score(memo: Memo, query: String) -> Double {
        let tokens = normalizedTokens(from: query)
        guard !tokens.isEmpty else { return 0 }

        let title = normalizedText(memo.title)
        let transcript = normalizedText(memo.transcriptText)
        let combined = "\(title) \(transcript)"

        var score = 0.0
        for token in tokens {
            if title.contains(token) {
                score += 3
            }
            if transcript.contains(token) {
                score += 1.5
            }
            score += Double(combined.components(separatedBy: token).count - 1) * 0.25
        }

        return score
    }

    public func rank(_ memos: [Memo], query: String) -> [Memo] {
        memos.sorted {
            let lhsScore = score(memo: $0, query: query)
            let rhsScore = score(memo: $1, query: query)
            if lhsScore == rhsScore {
                return $0.updatedAt > $1.updatedAt
            }
            return lhsScore > rhsScore
        }
    }

    private func normalizedTokens(from query: String) -> [String] {
        query
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func normalizedText(_ text: String) -> String {
        text.lowercased()
    }
}
