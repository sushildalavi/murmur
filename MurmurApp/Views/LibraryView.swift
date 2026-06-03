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
            ZStack {
                MurmurScreenBackground()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        header
                        resultsSummary

                        if viewModel.filteredMemos.isEmpty {
                            MurmurPanel(tint: .murmurCyan.opacity(0.18)) {
                                ContentUnavailableView(
                                    viewModel.searchText.isEmpty ? "No memos yet" : "No matches",
                                    systemImage: viewModel.searchText.isEmpty ? "mic.slash" : "magnifyingglass",
                                    description: Text(viewModel.searchText.isEmpty ? "Record your first memo and it will appear here." : "Try a different phrase or clear the search field.")
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                        } else {
                            ForEach(viewModel.filteredMemos) { memo in
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
            .navigationTitle("Library")
            .murmurInlineTitle()
            .searchable(text: $viewModel.searchText, prompt: "Search titles or transcript")
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    private var header: some View {
        let metrics = MemoMetrics.calculate(from: viewModel.memos)

        return MurmurPanel(tint: .murmurCyan.opacity(0.20)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Library")
                            .font(.largeTitle.bold())
                        Text("Everything stays local, searchable, and organized with a clean memo archive.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.murmurCyan, .murmurViolet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurCyan, .murmurMint, .murmurOrange])

                HStack(spacing: 12) {
                    MurmurStatusPill(title: "\(metrics.totalMemos) memos", symbol: "tray.full.fill", tint: .murmurCyan)
                    MurmurStatusPill(title: "\(metrics.memoDaysActive) active days", symbol: "calendar.circle.fill", tint: .murmurOrange)
                }
            }
        }
    }

    private var resultsSummary: some View {
        HStack(spacing: 12) {
            MurmurStatCard(
                title: "Results",
                value: "\(viewModel.filteredMemos.count)",
                detail: viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "All saved memos" : "Matching your search",
                symbol: "tray.full",
                tint: .cyan
            )

            MurmurStatCard(
                title: "Latest",
                value: latestMemoLabel,
                detail: "Most recent memo in the library",
                symbol: "clock.arrow.circlepath",
                tint: .orange
            )
        }
    }

    private var latestMemoLabel: String {
        guard let latest = viewModel.memos.max(by: { $0.updatedAt < $1.updatedAt }) else {
            return "—"
        }

        return latest.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}
