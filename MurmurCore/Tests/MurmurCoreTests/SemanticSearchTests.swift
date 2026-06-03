import Foundation
import XCTest
@testable import MurmurCore

final class SemanticSearchTests: XCTestCase {

    private func memo(_ title: String, _ body: String) -> Memo {
        Memo(
            title: title,
            audioFileURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            transcriptSegments: [TranscriptSegment(text: body, startTime: 0, endTime: 1)]
        )
    }

    // MARK: Embeddings

    func testCosineSimilarityBounds() {
        let v: [Double] = [1, 2, 3, 4]
        XCTAssertEqual(EmbeddingService.cosineSimilarity(v, v), 1.0, accuracy: 1e-9)
        XCTAssertEqual(EmbeddingService.cosineSimilarity([1, 0], [0, 1]), 0.0, accuracy: 1e-9)
        XCTAssertEqual(EmbeddingService.cosineSimilarity([1, 0], [-1, 0]), -1.0, accuracy: 1e-9)
        XCTAssertEqual(EmbeddingService.cosineSimilarity([], []), 0.0)
    }

    func testEmbeddingPlacesRelatedTextCloser() throws {
        let service = EmbeddingService()
        try XCTSkipUnless(service.isAvailable, "On-device embedding model not available in this environment")

        let release = try XCTUnwrap(service.vector(for: "We shipped the product release today"))
        let launch = try XCTUnwrap(service.vector(for: "The launch went out to customers"))
        let groceries = try XCTUnwrap(service.vector(for: "I bought apples and bread at the store"))

        let related = EmbeddingService.cosineSimilarity(release, launch)
        let unrelated = EmbeddingService.cosineSimilarity(release, groceries)
        XCTAssertGreaterThan(related, unrelated)
    }

    // MARK: Semantic index

    func testSemanticIndexRanksByMeaningNotKeywords() throws {
        let index = SemanticMemoIndex()
        try XCTSkipUnless(index.isAvailable, "On-device embedding model not available in this environment")

        let shipping = memo("Release", "We deployed the new build and shipped it to production")
        let cooking = memo("Dinner", "Chopped onions and simmered the tomato sauce for pasta")
        let results = index.rankedMemos("software launch", in: [cooking, shipping], limit: 2)

        // "software launch" shares no words with either memo, but is semantically
        // closest to the shipping memo.
        XCTAssertEqual(results.first?.id, shipping.id)
    }

    // MARK: Hybrid fusion (deterministic, no model)

    func testReciprocalRankFusionPrefersConsistentlyHighItems() {
        let m1 = memo("A", "alpha")
        let m2 = memo("B", "beta")
        let m3 = memo("C", "gamma")

        // m1 ranks high in both lists; m3 only high in the second.
        let keyword = [m1, m2, m3]
        let semantic = [m3, m1, m2]
        let fused = HybridSearch.reciprocalRankFusion([keyword, semantic])

        XCTAssertEqual(fused.first?.id, m1.id)
        XCTAssertEqual(Set(fused.map(\.id)), Set([m1.id, m2.id, m3.id]))
    }

    func testReciprocalRankFusionDedupesAcrossLists() {
        let m1 = memo("A", "alpha")
        let m2 = memo("B", "beta")
        let fused = HybridSearch.reciprocalRankFusion([[m1, m2], [m2, m1]])
        XCTAssertEqual(fused.count, 2)
    }

    // MARK: RAG answer service (fallback paths, no model invocation)

    func testAnswerWithNoMemosReportsNothingFound() async {
        let service = MemoAnswerService(semanticIndex: SemanticMemoIndex())
        let answer = await service.answer(to: "what did I decide?", over: [])
        XCTAssertTrue(answer.sources.isEmpty)
        XCTAssertFalse(answer.usedAppleIntelligence)
        XCTAssertFalse(answer.text.isEmpty)
    }

    func testAnswerWithBlankQuestionPrompts() async {
        let service = MemoAnswerService(semanticIndex: SemanticMemoIndex())
        let answer = await service.answer(to: "   ", over: [memo("A", "alpha")])
        XCTAssertTrue(answer.sources.isEmpty)
    }

    func testExtractiveAnswerAttributesTopSource() {
        let top = memo("Standup", "Ship the dashboard. Then review the metrics.")
        let text = MemoAnswerService.extractiveAnswer(for: [top])
        XCTAssertTrue(text.contains("Standup"))
        XCTAssertTrue(text.contains("Ship the dashboard"))
    }
}
