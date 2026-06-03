import Foundation
import XCTest
@testable import MurmurCore

final class MurmurCoreTests: XCTestCase {
    func testPackageLoads() {
        let core = MurmurCore()
        XCTAssertNotNil(core)
    }

    func testCryptoRoundTripMemo() throws {
        let service = CryptoService()
        let key = service.makeSymmetricKey()
        let memo = Memo(
            title: "Standup",
            audioFileURL: URL(fileURLWithPath: "/tmp/standup.m4a"),
            transcriptSegments: [
                TranscriptSegment(text: "Follow up with design", startTime: 0, endTime: 1)
            ]
        )

        let sealed = try service.seal(memo, using: key)
        let opened = try service.openMemo(sealed, using: key)

        XCTAssertEqual(opened.title, memo.title)
        XCTAssertEqual(opened.transcriptText, memo.transcriptText)
    }

    func testSummarizerProducesInsights() {
        let summarizer = Summarizer()
        let segments = [
            TranscriptSegment(text: "We need to follow up with design.", startTime: 0, endTime: 1),
            TranscriptSegment(text: "Action: send notes to team.", startTime: 1, endTime: 2)
        ]

        let insights = summarizer.summarize(segments)

        XCTAssertFalse(insights.summary.isEmpty)
        XCTAssertFalse(insights.actionItems.isEmpty)
        XCTAssertFalse(insights.keywords.isEmpty)
    }

    func testSearchIndexRanksByQuery() {
        var index = MemoSearchIndex()
        let memoOne = Memo(
            title: "Team planning",
            audioFileURL: URL(fileURLWithPath: "/tmp/team.m4a"),
            transcriptSegments: [TranscriptSegment(text: "Discuss roadmap and follow up", startTime: 0, endTime: 1)]
        )
        let memoTwo = Memo(
            title: "Weekend notes",
            audioFileURL: URL(fileURLWithPath: "/tmp/weekend.m4a"),
            transcriptSegments: [TranscriptSegment(text: "groceries and errands", startTime: 0, endTime: 1)]
        )

        index.upsert(memoTwo)
        index.upsert(memoOne)

        XCTAssertEqual(index.search("follow up").first?.id, memoOne.id)
    }

    func testConflictResolverPrefersNewestMemo() {
        let resolver = ConflictResolver()
        let baseURL = URL(fileURLWithPath: "/tmp/memo.m4a")
        let local = Memo(
            title: "Local",
            audioFileURL: baseURL,
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20)
        )
        let remote = Memo(
            title: "Remote",
            audioFileURL: baseURL,
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 15)
        )

        XCTAssertEqual(resolver.resolve(local: local, remote: remote).title, "Local")
    }

    func testSyncEngineFlushesPendingChanges() async throws {
        let client = InMemorySyncClient()
        var engine = SyncEngine(client: client)
        let mutation = PendingMutation(
            kind: .upsertMemo,
            memoID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            payload: Data("ciphertext".utf8)
        )
        engine.enqueue(mutation)

        let blobs = try await engine.sync()

        XCTAssertEqual(blobs.count, 1)
        XCTAssertEqual(blobs.first?.memoID.uuidString, "11111111-1111-1111-1111-111111111111")
    }
}
