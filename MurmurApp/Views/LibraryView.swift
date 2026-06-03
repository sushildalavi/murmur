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
            List(viewModel.filteredMemos) { memo in
                NavigationLink(memo.title) {
                    MemoDetailView(viewModel: MemoDetailViewModel(memo: memo))
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchText)
            .onAppear {
                viewModel.refresh()
            }
            .overlay {
                if viewModel.filteredMemos.isEmpty {
                    ContentUnavailableView("No memos yet", systemImage: "mic.slash")
                }
            }
        }
    }
}
