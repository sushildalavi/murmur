import SwiftUI
import MurmurCore

@MainActor
struct MetricsView: View {
    @State private var viewModel: MetricsViewModel

    init(viewModel: MetricsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    metricCard(title: "Memos", value: "\(viewModel.metrics.totalMemos)", subtitle: "Saved locally")
                    metricCard(title: "Segments", value: "\(viewModel.metrics.totalTranscriptSegments)", subtitle: "Transcript chunks")
                    metricCard(title: "Words", value: "\(viewModel.metrics.totalWords)", subtitle: "Local transcript volume")
                    metricCard(
                        title: "Active Days",
                        value: "\(viewModel.metrics.memoDaysActive)",
                        subtitle: "Distinct days with memos"
                    )

                    if let latestMemoDate = viewModel.metrics.latestMemoDate {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Latest Activity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(latestMemoDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Metrics")
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
