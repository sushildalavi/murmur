import SwiftUI
import MurmurCore

@MainActor
struct MetricsView: View {
    @State private var viewModel: MetricsViewModel

    init(viewModel: MetricsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var metrics: MemoMetrics {
        viewModel.metrics
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MurmurScreenBackground()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        hero

                        LazyVGrid(columns: columns, spacing: 12) {
                            MurmurStatCard(
                                title: "Memos",
                                value: "\(metrics.totalMemos)",
                                detail: "Saved locally",
                                symbol: "mic.circle.fill",
                                tint: .cyan
                            )

                            MurmurStatCard(
                                title: "Segments",
                                value: "\(metrics.totalTranscriptSegments)",
                                detail: "Transcript chunks",
                                symbol: "text.quote",
                                tint: .orange
                            )

                            MurmurStatCard(
                                title: "Words",
                                value: "\(metrics.totalWords)",
                                detail: "Local transcript volume",
                                symbol: "number.square.fill",
                                tint: .green
                            )

                            MurmurStatCard(
                                title: "Active days",
                                value: "\(metrics.memoDaysActive)",
                                detail: "Distinct days with memos",
                                symbol: "calendar.circle.fill",
                                tint: .blue
                            )
                        }

                        section(title: "Final metrics", eyebrow: "Efficiency") {
                            LazyVGrid(columns: columns, spacing: 12) {
                                MurmurStatCard(
                                    title: "Words / memo",
                                    value: formatted(metrics.averageWordsPerMemo),
                                    detail: "Average memo length",
                                    symbol: "text.word.spacing",
                                    tint: .cyan
                                )

                                MurmurStatCard(
                                    title: "Segments / memo",
                                    value: formatted(metrics.averageSegmentsPerMemo),
                                    detail: "Average transcript slices",
                                    symbol: "line.3.horizontal.decrease.circle",
                                    tint: .orange
                                )

                                MurmurStatCard(
                                    title: "Words / segment",
                                    value: formatted(metrics.averageWordsPerSegment),
                                    detail: "Density of the transcript",
                                    symbol: "arrow.up.right.circle.fill",
                                    tint: .green
                                )

                                MurmurStatCard(
                                    title: "Memos / active day",
                                    value: formatted(metrics.memosPerActiveDay),
                                    detail: "Cadence of usage",
                                    symbol: "chart.line.uptrend.xyaxis",
                                    tint: .blue
                                )
                            }
                        }

                        if let latestMemoDate = metrics.latestMemoDate {
                            MurmurPanel(tint: .murmurOrange.opacity(0.18)) {
                                HStack(alignment: .center, spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.murmurOrange, .murmurViolet],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 42, height: 42)
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Latest activity")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text(latestMemoDate.formatted(date: .complete, time: .shortened))
                                            .font(.headline)
                                        Text("The most recent memo update in the archive.")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Metrics")
            .murmurInlineTitle()
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    private var hero: some View {
        MurmurPanel(tint: .murmurOrange.opacity(0.20)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Metrics")
                            .font(.largeTitle.bold())
                        Text("A production-style snapshot of local usage, transcript density, and memo cadence.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.murmurOrange, .murmurGold, .murmurViolet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurOrange, .murmurGold, .murmurViolet, .murmurCyan])

                HStack(spacing: 10) {
                    MurmurStatusPill(title: "Local analytics", symbol: "lock.fill", tint: .murmurLime)
                    MurmurStatusPill(title: "Real-time refresh", symbol: "bolt.fill", tint: .murmurCyan)
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, eyebrow: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            MurmurSectionHeader(title, eyebrow: eyebrow)
            content()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private func formatted(_ value: Double) -> String {
        value == 0 ? "0" : value.formatted(.number.precision(.fractionLength(1)))
    }
}
