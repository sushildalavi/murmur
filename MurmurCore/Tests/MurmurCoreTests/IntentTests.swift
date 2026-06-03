import Foundation
import XCTest
@testable import MurmurCore

final class IntentTests: XCTestCase {

    func testCreateActionItemIntentExtractsActionItems() {
        let intent = CreateActionItemIntent(
            transcript: "We shipped the build. Follow up with design on the spec. Need to update the changelog."
        )
        let items = intent.actionItems()
        XCTAssertTrue(items.contains { $0.lowercased().contains("follow up") })
        XCTAssertTrue(items.contains { $0.lowercased().contains("need to") })
        XCTAssertFalse(items.contains { $0.lowercased().contains("we shipped the build") })
    }

    func testCreateActionItemIntentEmptyTranscript() {
        XCTAssertTrue(CreateActionItemIntent(transcript: "").actionItems().isEmpty)
    }

    func testSearchMemosIntentRanksByQuery() {
        let planning = Memo(
            title: "Planning",
            audioFileURL: URL(fileURLWithPath: "/tmp/p.m4a"),
            transcriptSegments: [TranscriptSegment(text: "discuss the roadmap and follow up", startTime: 0, endTime: 1)]
        )
        let weekend = Memo(
            title: "Weekend",
            audioFileURL: URL(fileURLWithPath: "/tmp/w.m4a"),
            transcriptSegments: [TranscriptSegment(text: "groceries and errands", startTime: 0, endTime: 1)]
        )
        let intent = SearchMemosIntent(query: "follow up")
        XCTAssertEqual(intent.results(from: [weekend, planning]).first?.id, planning.id)
    }

    func testRouterExtractsQueryAndDateHint() {
        let router = MemoIntentRouter()
        let route = router.route(for: "Ask Murmur what I said about rent yesterday")
        XCTAssertEqual(route, .ask(question: "rent", dateHint: .yesterday))
    }

    func testSummarizeLatestMemoIntentSummaryHelper() async {
        let original = await MainActor.run { MemoStore.shared.memos }

        await MainActor.run {
            MemoStore.shared.removeAll()
            MemoStore.shared.upsert(
                Memo(
                    title: "Kickoff",
                    audioFileURL: URL(fileURLWithPath: "/tmp/kickoff.m4a"),
                    transcriptSegments: [
                        TranscriptSegment(text: "We need to follow up with design.", startTime: 0, endTime: 1)
                    ]
                )
            )
        }

        let result = await SummarizeLatestMemoIntent().summary()
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.text.isEmpty ?? true)

        await MainActor.run {
            MemoStore.shared.removeAll()
            original.forEach { MemoStore.shared.upsert($0) }
        }
    }

    func testSyncMemosIntentReportsNotConfiguredWithoutEnvironment() async {
        let result = await SyncMemosIntent().syncConfiguredMemos(environment: [:], secretStore: InMemorySecretStore())
        if case .notConfigured = result {
        } else {
            XCTFail("Expected sync to be disabled when MURMUR_SYNC_URL is missing")
        }
    }

    func testExtractActionItemsIntentUsesLatestMemo() async {
        let original = await MainActor.run { MemoStore.shared.memos }
        await MainActor.run {
            MemoStore.shared.removeAll()
            MemoStore.shared.upsert(
                Memo(
                    title: "Follow Up",
                    audioFileURL: URL(fileURLWithPath: "/tmp/followup.m4a"),
                    transcriptSegments: [
                        TranscriptSegment(text: "Follow up with design on the spec.", startTime: 0, endTime: 1)
                    ]
                )
            )
        }

        let items = await ExtractActionItemsIntent().actionItems()
        XCTAssertFalse(items.isEmpty)

        await MainActor.run {
            MemoStore.shared.removeAll()
            original.forEach { MemoStore.shared.upsert($0) }
        }
    }

#if canImport(AppIntents)
    func testStartRecordingIntentPostsNotification() async throws {
        let expectation = expectation(forNotification: .murmurStartRecordingRequested, object: nil)
        _ = try await StartRecordingIntent().perform()
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testStopRecordingIntentPostsNotification() async throws {
        let expectation = expectation(forNotification: .murmurStopRecordingRequested, object: nil)
        _ = try await StopRecordingIntent().perform()
        await fulfillment(of: [expectation], timeout: 1)
    }
#endif
}
