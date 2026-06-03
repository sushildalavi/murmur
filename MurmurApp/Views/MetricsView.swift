import SwiftUI
import MurmurCore

@MainActor
struct MetricsView: View {
    @State private var viewModel: MetricsViewModel

    init(viewModel: MetricsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var metrics: MemoMetrics { viewModel.metrics }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if metrics.totalMemos == 0 {
                    ContentUnavailableView(
                        "No Metrics Yet",
                        systemImage: "chart.bar",
                        description: Text("Record a few memos to see your library statistics.")
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Metrics")
            .onAppear { viewModel.refresh() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                group(title: "Library") {
                    MurmurStatTile(title: "Memos", value: "\(metrics.totalMemos)", symbol: "waveform", caption: "Saved locally")
                    MurmurStatTile(title: "Words", value: "\(metrics.totalWords)", symbol: "text.alignleft", caption: "Total transcribed")
                    MurmurStatTile(title: "Segments", value: "\(metrics.totalTranscriptSegments)", symbol: "text.quote", caption: "Transcript chunks")
                    MurmurStatTile(title: "Active Days", value: "\(metrics.memoDaysActive)", symbol: "calendar", caption: "Days with memos")
                }

                group(title: "Averages") {
                    MurmurStatTile(title: "Words / Memo", value: formatted(metrics.averageWordsPerMemo), symbol: "doc.text", caption: "Memo length")
                    MurmurStatTile(title: "Segments / Memo", value: formatted(metrics.averageSegmentsPerMemo), symbol: "list.bullet", caption: "Transcript slices")
                    MurmurStatTile(title: "Words / Segment", value: formatted(metrics.averageWordsPerSegment), symbol: "arrow.left.and.right", caption: "Transcript density")
                    MurmurStatTile(title: "Memos / Day", value: formatted(metrics.memosPerActiveDay), symbol: "chart.line.uptrend.xyaxis", caption: "Usage cadence")
                }

                if let latest = metrics.latestMemoDate {
                    latestActivity(latest)
                }
            }
            .padding()
        }
        .murmurGroupedScreen()
    }

    @ViewBuilder
    private func group(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
            LazyVGrid(columns: columns, spacing: 12) {
                content()
            }
        }
    }

    private func latestActivity(_ date: Date) -> some View {
        MurmurCard {
            HStack(spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.murmurAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest Activity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                }
                Spacer()
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value == 0 ? "0" : value.formatted(.number.precision(.fractionLength(1)))
    }
}
