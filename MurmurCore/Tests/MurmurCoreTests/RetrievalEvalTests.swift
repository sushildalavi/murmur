import Foundation
import XCTest
@testable import MurmurCore

/// A small labeled evaluation of the on-device semantic retriever. The queries
/// deliberately share few or no literal words with their target memo, so this
/// measures meaning-based retrieval rather than keyword overlap. Reports
/// Recall@1, Recall@3, and Mean Reciprocal Rank.
final class RetrievalEvalTests: XCTestCase {

    private func memo(_ title: String, _ body: String) -> Memo {
        Memo(
            title: title,
            audioFileURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            transcriptSegments: [TranscriptSegment(text: body, startTime: 0, endTime: 1)]
        )
    }

    func testSemanticRetrievalQualityOnLabeledSet() throws {
        let index = SemanticMemoIndex()
        try XCTSkipUnless(index.isAvailable, "On-device embedding model not available in this environment")

        let corpus = [
            memo("Release planning", "We finalized the launch date and the go-to-market plan for shipping."),
            memo("Grocery list", "Buy milk, eggs, bread, and apples from the supermarket."),
            memo("Doctor appointment", "Schedule a dentist visit and refill the prescription next week."),
            memo("Budget review", "Go over monthly expenses, savings, and the investment portfolio."),
            memo("Gym workout", "Leg day with squats, deadlifts, and a long run on the treadmill.")
        ]
        // (query, expected memo title) — low literal overlap with the target.
        let labeled: [(query: String, target: String)] = [
            ("when are we shipping the product", "Release planning"),
            ("things to pick up at the store", "Grocery list"),
            ("medical visit reminder", "Doctor appointment"),
            ("look over my finances", "Budget review"),
            ("exercise routine for today", "Gym workout")
        ]

        var hitsAt1 = 0, hitsAt3 = 0
        var reciprocalRankSum = 0.0

        for (query, target) in labeled {
            let ranked = index.rankedMemos(query, in: corpus, limit: corpus.count)
            guard let rank = ranked.firstIndex(where: { $0.title == target }) else { continue }
            if rank == 0 { hitsAt1 += 1 }
            if rank < 3 { hitsAt3 += 1 }
            reciprocalRankSum += 1.0 / Double(rank + 1)
        }

        let n = Double(labeled.count)
        let recallAt1 = Double(hitsAt1) / n
        let recallAt3 = Double(hitsAt3) / n
        let mrr = reciprocalRankSum / n
        print(String(format: "Retrieval eval — Recall@1=%.2f Recall@3=%.2f MRR=%.2f (n=%d)", recallAt1, recallAt3, mrr, labeled.count))

        // Conservative thresholds: the retriever should reliably surface the
        // right memo in the top 3 and usually rank it first.
        XCTAssertGreaterThanOrEqual(recallAt3, 0.8, "Recall@3 below threshold")
        XCTAssertGreaterThanOrEqual(mrr, 0.6, "MRR below threshold")
    }
}
