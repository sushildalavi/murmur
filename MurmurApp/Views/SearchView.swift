import SwiftUI
import MurmurCore

@MainActor
struct SearchView: View {
    @State private var query = ""
    @State private var memoStore: MemoStore

    init(memoStore: MemoStore) {
        _memoStore = State(initialValue: memoStore)
    }

    /// Ranked results from the store's search (FTS5 when persistence is
    /// available, the in-memory ranking index otherwise) — the same path the
    /// rest of the app uses, not a naive substring scan.
    private var results: [Memo] {
        memoStore.search(query)
    }

    var body: some View {
        NavigationStack {
            Group {
                if memoStore.memos.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Search",
                        systemImage: "magnifyingglass",
                        description: Text("Record a memo and then search by topic, phrase, or title.")
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search titles or transcript")
        }
    }

    private var resultsList: some View {
        List {
            Section {
                ForEach(results) { memo in
                    NavigationLink {
                        MemoDetailView(viewModel: MemoDetailViewModel(memo: memo))
                    } label: {
                        MurmurMemoRow(memo: memo, snippet: memo.transcriptText)
                    }
                }
            } header: {
                Text(headerText)
            }
        }
    }

    private var headerText: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = results.count
        let noun = count == 1 ? "result" : "results"
        return trimmed.isEmpty ? "All memos" : "\(count) \(noun)"
    }
}
