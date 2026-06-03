import Foundation

/// Fuses several ranked result lists into one using Reciprocal Rank Fusion.
///
/// RRF is a simple, robust way to combine rankings that come from different
/// scoring systems (here: FTS5 keyword `bm25` and embedding cosine similarity)
/// without having to normalize their scores onto a common scale. Each list
/// contributes `1 / (k + rank)` to every item it contains; items that rank
/// highly across both lists rise to the top.
public enum HybridSearch {
    public static func reciprocalRankFusion(_ rankings: [[Memo]], k: Double = 60) -> [Memo] {
        var scores: [UUID: Double] = [:]
        var byID: [UUID: Memo] = [:]

        for ranking in rankings {
            for (index, memo) in ranking.enumerated() {
                scores[memo.id, default: 0] += 1 / (k + Double(index + 1))
                byID[memo.id] = memo
            }
        }

        return scores
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    // Stable tiebreak by most recently updated.
                    return (byID[lhs.key]?.updatedAt ?? .distantPast) > (byID[rhs.key]?.updatedAt ?? .distantPast)
                }
                return lhs.value > rhs.value
            }
            .compactMap { byID[$0.key] }
    }
}
