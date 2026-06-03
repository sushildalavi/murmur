import SwiftUI
import MurmurCore

@MainActor
struct SearchView: View {
    @State private var query = ""
    @State private var memoStore: MemoStore

    init(memoStore: MemoStore) {
        _memoStore = State(initialValue: memoStore)
    }

    private var filteredMemos: [Memo] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return memoStore.memos }
        return memoStore.memos.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.transcriptText.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredMemos) { memo in
                VStack(alignment: .leading) {
                    Text(memo.title)
                    Text(memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query)
        }
    }
}
