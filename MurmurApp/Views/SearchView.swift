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
            ZStack {
                MurmurScreenBackground()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        header
                        summary

                        if filteredMemos.isEmpty {
                            MurmurPanel(tint: .murmurViolet.opacity(0.18)) {
                                ContentUnavailableView(
                                    query.isEmpty ? "No memos yet" : "No results",
                                    systemImage: query.isEmpty ? "magnifyingglass.circle" : "sparkles",
                                    description: Text(query.isEmpty ? "Create a memo and then search by topic, phrase, or title." : "Try a different phrase or clear the search field.")
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                        } else {
                            ForEach(filteredMemos) { memo in
                                NavigationLink {
                                    MemoDetailView(viewModel: MemoDetailViewModel(memo: memo))
                                } label: {
                                    MurmurMemoRow(memo: memo, snippet: memo.transcriptText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Search")
            .murmurInlineTitle()
            .searchable(text: $query, prompt: "Search titles or transcript")
        }
    }

    private var header: some View {
        let metrics = MemoMetrics.calculate(from: memoStore.memos)

        return MurmurPanel(tint: .murmurViolet.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Search")
                            .font(.largeTitle.bold())
                        Text("Find memos by title, keywords, or transcript text with a local-first search experience.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.murmurViolet, .murmurCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurViolet, .murmurCyan, .murmurOrange])

                HStack(spacing: 12) {
                    MurmurStatusPill(title: "\(metrics.totalMemos) total", symbol: "tray.full.fill", tint: .murmurCyan)
                    MurmurStatusPill(title: "\(metrics.totalWords) words", symbol: "text.word.spacing", tint: .murmurOrange)
                }
            }
        }
    }

    private var summary: some View {
        MurmurPanel(tint: .murmurCyan.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Search scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(filteredMemos.count) result\(filteredMemos.count == 1 ? "" : "s")")
                    .font(.title3.bold())
                Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "All saved memos are available." : "Matches your current search phrase.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
