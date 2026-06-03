import Foundation
import Observation
import MurmurCore

@MainActor
@Observable
final class LibraryViewModel {
    var searchText: String = ""
    var memos: [Memo] = []

    @ObservationIgnored private let memoStore: MemoStore

    init(memoStore: MemoStore) {
        self.memoStore = memoStore
        self.memos = memoStore.memos
    }

    func refresh() {
        memos = memoStore.memos
    }

    var filteredMemos: [Memo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return memos }
        return memos.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.transcriptText.localizedCaseInsensitiveContains(query)
        }
    }
}
