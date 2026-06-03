import Foundation
import XCTest
@testable import MurmurCore

final class PersistenceTests: XCTestCase {

    // MARK: Helpers

    private func tempPath() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".sqlite")
            .path
    }

    private func makeStore() throws -> SQLiteMemoStore {
        try SQLiteMemoStore(path: tempPath())
    }

    private func memo(title: String, body: String, id: UUID = UUID(), at date: Date = Date()) -> Memo {
        Memo(
            id: id,
            title: title,
            audioFileURL: URL(fileURLWithPath: "/tmp/\(id.uuidString).m4a"),
            createdAt: date,
            updatedAt: date,
            transcriptSegments: [TranscriptSegment(text: body, startTime: 0, endTime: 1)]
        )
    }

    // MARK: Durability

    func testMemosSurviveAcrossStoreInstances() throws {
        let path = tempPath()
        let id = UUID()
        do {
            let store = try SQLiteMemoStore(path: path)
            try store.save(memo(title: "Kickoff", body: "ship the release", id: id))
        }
        // A brand-new instance over the same file must see the saved memo.
        let reopened = try SQLiteMemoStore(path: path)
        let loaded = try reopened.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, id)
        XCTAssertEqual(loaded.first?.title, "Kickoff")
        XCTAssertEqual(loaded.first?.transcriptText, "ship the release")
    }

    func testLoadOrdersByMostRecentlyUpdated() throws {
        let store = try makeStore()
        let older = memo(title: "Older", body: "a", at: Date(timeIntervalSince1970: 100))
        let newer = memo(title: "Newer", body: "b", at: Date(timeIntervalSince1970: 200))
        try store.save(older)
        try store.save(newer)
        XCTAssertEqual(try store.load().map(\.title), ["Newer", "Older"])
    }

    // MARK: Full-text search

    func testFullTextSearchRanksAndFilters() throws {
        let store = try makeStore()
        let roadmap = memo(title: "Planning", body: "discuss the roadmap and follow up")
        let groceries = memo(title: "Weekend", body: "groceries and errands")
        try store.save(groceries)
        try store.save(roadmap)

        XCTAssertEqual(try store.search("roadmap").map(\.id), [roadmap.id])
        XCTAssertEqual(try store.search("").count, 2) // empty query returns everything
        XCTAssertTrue(try store.search("xyznotpresent").isEmpty)
    }

    func testPrefixSearchMatchesPartialTerms() throws {
        let store = try makeStore()
        let item = memo(title: "Engineering", body: "transcription pipeline")
        try store.save(item)
        XCTAssertEqual(try store.search("transc").first?.id, item.id)
    }

    func testUpsertReplacesAndReindexes() throws {
        let store = try makeStore()
        let id = UUID()
        try store.save(memo(title: "Old", body: "alpha keyword", id: id))
        try store.save(memo(title: "New", body: "beta keyword", id: id))

        XCTAssertEqual(try store.load().count, 1)
        XCTAssertEqual(try store.load().first?.title, "New")
        XCTAssertTrue(try store.search("alpha").isEmpty) // stale text is reindexed away
        XCTAssertEqual(try store.search("beta").first?.id, id)
    }

    func testDeleteRemovesFromStoreAndIndex() throws {
        let store = try makeStore()
        let id = UUID()
        try store.save(memo(title: "Temp", body: "deletable content", id: id))
        try store.delete(id: id)
        XCTAssertTrue(try store.load().isEmpty)
        XCTAssertTrue(try store.search("deletable").isEmpty)
    }

    func testStatsReportCountAndSize() throws {
        let store = try makeStore()
        try store.save(memo(title: "A", body: "one"))
        try store.save(memo(title: "B", body: "two"))
        let stats = try store.stats()
        XCTAssertEqual(stats.memoCount, 2)
        XCTAssertGreaterThan(stats.databaseByteSize, 0)
    }

    func testSearchQuotingIsInjectionSafe() throws {
        let store = try makeStore()
        let item = memo(title: "Notes", body: "alpha beta gamma")
        try store.save(item)
        // FTS operators in user input must not crash or throw; they are sanitized.
        XCTAssertNoThrow(try store.search("alpha OR (beta"))
        XCTAssertNoThrow(try store.search("\"unterminated"))
    }

    // MARK: MemoStore integration

    @MainActor
    func testMemoStoreLoadsFromPersistenceOnInit() throws {
        let store = try makeStore()
        try store.save(memo(title: "Persisted", body: "loaded on launch"))
        let memoStore = MemoStore(persistence: store)
        XCTAssertEqual(memoStore.memos.count, 1)
        XCTAssertEqual(memoStore.memos.first?.title, "Persisted")
    }

    @MainActor
    func testMemoStoreUpsertAndRemovePersist() throws {
        let store = try makeStore()
        let memoStore = MemoStore(persistence: store)
        let item = memo(title: "Doomed", body: "remove me")
        memoStore.upsert(item)
        XCTAssertEqual(try store.load().count, 1)

        memoStore.remove(id: item.id)
        XCTAssertTrue(memoStore.memos.isEmpty)
        XCTAssertTrue(try store.load().isEmpty)
    }

    // MARK: Privacy invariant
    //
    // The build should fail if a synced payload ever carries plaintext. This is
    // the encrypted-sync analog of a "nothing leaves the device in the clear"
    // guarantee — asserted, not just documented.

    func testSyncPayloadIsCiphertextNotPlaintext() async throws {
        let marker = "TOPSECRETMARKER"
        let client = InMemorySyncClient()
        let service = MemoSyncService(client: client, secretStore: InMemorySecretStore())
        let secret = Memo(
            title: marker,
            audioFileURL: URL(fileURLWithPath: "/tmp/secret.m4a"),
            transcriptSegments: [TranscriptSegment(text: "\(marker) private words", startTime: 0, endTime: 1)]
        )

        try await service.sync(secret)
        let blobs = try await client.fetchChanges(since: nil)
        let ciphertext = try XCTUnwrap(blobs.first?.ciphertext)

        XCTAssertFalse(
            ciphertext.containsSubsequence(Array(marker.utf8)),
            "plaintext marker leaked into the sync payload"
        )
        XCTAssertNil(
            try? JSONDecoder().decode(Memo.self, from: ciphertext),
            "sync payload should not be a decodable plaintext memo"
        )
    }
}

private extension Data {
    func containsSubsequence(_ pattern: [UInt8]) -> Bool {
        guard !pattern.isEmpty, count >= pattern.count else { return false }
        let bytes = [UInt8](self)
        for start in 0...(bytes.count - pattern.count) where Array(bytes[start..<start + pattern.count]) == pattern {
            return true
        }
        return false
    }
}
