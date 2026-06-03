import SwiftUI
import MurmurCore

@MainActor
struct LibraryView: View {
    @State private var viewModel: LibraryViewModel

    init(viewModel: LibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.memos.isEmpty {
                    ContentUnavailableView(
                        "No Memos Yet",
                        systemImage: "mic.slash",
                        description: Text("Record your first memo and it will appear here.")
                    )
                } else if viewModel.filteredMemos.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    memoList
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchText, prompt: "Search titles or transcript")
            .onAppear { viewModel.refresh() }
        }
    }

    private var memoList: some View {
        List {
            Section {
                ForEach(viewModel.filteredMemos) { memo in
                    NavigationLink {
                        MemoDetailView(viewModel: MemoDetailViewModel(memo: memo))
                    } label: {
                        MurmurMemoRow(memo: memo, snippet: memo.transcriptText)
                    }
                }
                .onDelete(perform: viewModel.delete)
            } header: {
                Text(headerText)
            }
        }
    }

    private var headerText: String {
        let count = viewModel.filteredMemos.count
        let noun = count == 1 ? "memo" : "memos"
        return viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(count) \(noun)"
            : "\(count) \(noun) matching"
    }
}
