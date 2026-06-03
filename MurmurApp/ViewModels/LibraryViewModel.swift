import Foundation
import Observation
import MurmurCore

@MainActor
@Observable
final class LibraryViewModel {
    var searchText: String = ""
    var memos: [Memo] = []

    @ObservationIgnored private let memoStore: MemoStore
    @ObservationIgnored private let semanticIndex: SemanticMemoIndex

    init(memoStore: MemoStore, semanticIndex: SemanticMemoIndex) {
        self.memoStore = memoStore
        self.semanticIndex = semanticIndex
        self.memos = memoStore.memos
    }

    func refresh() {
        memos = memoStore.memos
    }

    func delete(at offsets: IndexSet) {
        let targets = offsets.map { filteredMemos[$0] }
        for memo in targets {
            memoStore.remove(id: memo.id)
        }
        refresh()
    }

    /// Hybrid search: fuses the FTS5 keyword ranking with on-device semantic
    /// ranking via Reciprocal Rank Fusion, so results match both exact words and
    /// meaning. Falls back to keyword-only when embeddings are unavailable.
    var filteredMemos: [Memo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return memos }

        let keyword = memoStore.search(query)
        let semantic = semanticIndex.rankedMemos(query, in: memos, limit: 20, threshold: 0.15)
        guard !semantic.isEmpty else { return keyword }
        return HybridSearch.reciprocalRankFusion([keyword, semantic])
    }
}
