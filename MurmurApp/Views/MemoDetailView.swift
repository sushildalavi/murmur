import SwiftUI
import MurmurCore

@MainActor
struct MemoDetailView: View {
    @State private var viewModel: MemoDetailViewModel

    init(viewModel: MemoDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var memo: Memo { viewModel.memo }

    private var wordCount: Int {
        memo.transcriptText.split { $0.isWhitespace || $0.isNewline }.count
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(memo.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        MurmurBadge(title: "\(memo.transcriptSegments.count) segments", symbol: "text.quote")
                        MurmurBadge(title: "\(wordCount) words", symbol: "number")
                    }

                    AudioPlayerView(url: memo.audioFileURL)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            insightsSection

            Section("Transcript") {
                if memo.transcriptSegments.isEmpty {
                    ContentUnavailableView(
                        "No Transcript",
                        systemImage: "text.bubble",
                        description: Text("This memo was saved before transcription completed.")
                    )
                } else {
                    ForEach(memo.transcriptSegments) { segment in
                        MurmurTranscriptRow(segment: segment)
                    }
                }
            }

            Section("Details") {
                LabeledContent("Audio file") {
                    Text(memo.audioFileURL.lastPathComponent)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                LabeledContent("Updated", value: memo.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle(memo.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    @ViewBuilder
    private var insightsSection: some View {
        if viewModel.hasTranscript {
            Section("Insights") {
                if let insights = viewModel.insights {
                    if !insights.summary.isEmpty {
                        Text(insights.summary)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !insights.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Action Items")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(insights.actionItems, id: \.self) { item in
                                Label(item, systemImage: "checkmark.circle")
                                    .font(.subheadline)
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }

                    if !insights.keywords.isEmpty {
                        ViewThatFits(in: .horizontal) {
                            keywordRow(insights.keywords)
                            keywordRow(insights.keywords)
                        }
                    }
                } else {
                    Button {
                        Task { await viewModel.generateInsights() }
                    } label: {
                        if viewModel.isGenerating {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Generating…")
                            }
                        } else {
                            Label("Generate Summary", systemImage: "sparkles")
                        }
                    }
                    .disabled(viewModel.isGenerating)

                    Text(intelligenceFootnote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func keywordRow(_ keywords: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(keywords.prefix(5), id: \.self) { keyword in
                MurmurBadge(title: keyword, symbol: "tag")
            }
        }
    }

    private var intelligenceFootnote: String {
        switch viewModel.intelligenceStatus {
        case .available:
            return "Generated on device with Apple Intelligence."
        case .unavailable(let reason):
            return reason
        }
    }
}
