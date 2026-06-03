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

    func testHTTPSyncClientRoundTripsRequests() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPSyncClient(baseURL: URL(string: "https://example.com")!, session: session)
        let memoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw NSError(domain: "MurmurTests", code: 1)
            }

            if request.httpMethod == "POST" {
                let response = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }

            if request.httpMethod == "DELETE" {
                let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }

            let body = #"{"blobs":[{"memo_id":"11111111-1111-1111-1111-111111111111","ciphertext":"Y2lwaGVydGV4dA==","created_at":"2026-06-02T20:00:00.000Z","updated_at":"2026-06-02T20:00:00.000Z"}]}"#
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        try await client.push(
            SyncBlob(
                memoID: memoID,
                ciphertext: Data("ciphertext".utf8),
                createdAt: Date(timeIntervalSince1970: 10),
                updatedAt: Date(timeIntervalSince1970: 10)
            )
        )

        let blobs = try await client.fetchChanges(since: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(blobs.count, 1)
        XCTAssertEqual(blobs.first?.memoID, memoID)

        try await client.delete(memoID: memoID)
    }

    func testMemoSyncServiceEncryptsAndRestoresMemo() async throws {
        let client = InMemorySyncClient()
        let store = InMemorySecretStore()
        let service = MemoSyncService(client: client, secretStore: store)
        let memo = Memo(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Encrypted memo",
            audioFileURL: URL(fileURLWithPath: "/tmp/encrypted.m4a"),
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20),
            transcriptSegments: [
                TranscriptSegment(text: "Keep this private", startTime: 0, endTime: 1)
            ]
        )

        try await service.sync(memo)
        let restored = try await service.fetchMemos()

        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored.first?.title, memo.title)
        XCTAssertEqual(restored.first?.transcriptText, memo.transcriptText)
    }

    func testMemoMetricsAggregateLocalData() {
        let calendar = Calendar(identifier: .gregorian)
        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let secondDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2))!

        let memos = [
            Memo(
                title: "Daily standup",
                audioFileURL: URL(fileURLWithPath: "/tmp/daily.m4a"),
                createdAt: firstDate,
                updatedAt: firstDate,
                transcriptSegments: [
                    TranscriptSegment(text: "Ship the metrics dashboard", startTime: 0, endTime: 1),
                    TranscriptSegment(text: "Validate screenshots", startTime: 1, endTime: 2)
                ]
            ),
            Memo(
                title: "Follow up",
                audioFileURL: URL(fileURLWithPath: "/tmp/followup.m4a"),
                createdAt: secondDate,
                updatedAt: secondDate,
                transcriptSegments: [
                    TranscriptSegment(text: "Review sync flow", startTime: 0, endTime: 1)
                ]
            )
        ]

        let metrics = MemoMetrics.calculate(from: memos, calendar: calendar)

        XCTAssertEqual(metrics.totalMemos, 2)
        XCTAssertEqual(metrics.totalTranscriptSegments, 3)
        XCTAssertEqual(metrics.totalWords, 9)
        XCTAssertEqual(metrics.latestMemoDate, secondDate)
        XCTAssertEqual(metrics.memoDaysActive, 2)
        XCTAssertEqual(metrics.memosPerActiveDay, 1)
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MurmurTests", code: 2))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
