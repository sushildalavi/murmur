import Foundation
import XCTest
@testable import MurmurMacApp
@testable import MurmurCore

@MainActor
final class ViewModelTests: XCTestCase {

    private func memo(_ title: String, _ body: String) -> Memo {
        Memo(
            title: title,
            audioFileURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            transcriptSegments: [TranscriptSegment(text: body, startTime: 0, endTime: 1)]
        )
    }

    // MARK: Library (hybrid search + delete)

    func testLibraryEmptyQueryReturnsAllMemos() {
        let store = MemoStore(memos: [memo("A", "alpha"), memo("B", "beta")])
        let viewModel = LibraryViewModel(memoStore: store, semanticIndex: SemanticMemoIndex())
        XCTAssertEqual(viewModel.filteredMemos.count, 2)
    }

    func testLibraryHybridSearchSurfacesRelevantMemo() {
        let shipping = memo("Release", "we deployed the build and shipped it to production")
        let cooking = memo("Dinner", "chopped onions and simmered the pasta sauce")
        let store = MemoStore(memos: [cooking, shipping])
        let viewModel = LibraryViewModel(memoStore: store, semanticIndex: SemanticMemoIndex())
        viewModel.searchText = "deployed build"
        XCTAssertEqual(viewModel.filteredMemos.first?.id, shipping.id)
    }

    func testLibraryDeleteRemovesMemo() {
        let target = memo("Doomed", "remove me")
        let store = MemoStore(memos: [target])
        let viewModel = LibraryViewModel(memoStore: store, semanticIndex: SemanticMemoIndex())
        viewModel.delete(at: IndexSet(integer: 0))
        XCTAssertTrue(viewModel.memos.isEmpty)
    }

    // MARK: Ask (canAsk gating; generation itself is covered in MurmurCore)

    func testAskCannotAskWithoutMemos() {
        let viewModel = AskViewModel(
            memoStore: MemoStore(memos: []),
            answerService: MemoAnswerService(semanticIndex: SemanticMemoIndex())
        )
        viewModel.question = "what did I decide?"
        XCTAssertFalse(viewModel.canAsk)
        XCTAssertFalse(viewModel.hasMemos)
    }

    func testAskCanAskWithMemoAndQuestion() {
        let viewModel = AskViewModel(
            memoStore: MemoStore(memos: [memo("Note", "ship the release")]),
            answerService: MemoAnswerService(semanticIndex: SemanticMemoIndex())
        )
        XCTAssertFalse(viewModel.canAsk) // empty question
        viewModel.question = "when do we ship?"
        XCTAssertTrue(viewModel.canAsk)
    }

    // MARK: Metrics & Settings

    func testMetricsViewModelComputesCounts() {
        let store = MemoStore(memos: [memo("A", "one two three"), memo("B", "four")])
        let viewModel = MetricsViewModel(memoStore: store)
        XCTAssertEqual(viewModel.metrics.totalMemos, 2)
        XCTAssertEqual(viewModel.metrics.totalWords, 4)
    }

    func testSettingsViewModelDefaults() {
        let viewModel = SettingsViewModel(syncStatus: "Encrypted sync enabled")
        XCTAssertTrue(viewModel.isPrivacyModeEnabled)
        XCTAssertEqual(viewModel.keyStatus, "Encrypted sync enabled")
    }

    func testLiveContainerDisablesSyncWhenEnvironmentIsEmpty() {
        XCTAssertNil(MurmurAppContainer.liveSyncService(environment: [:]))
    }
}
