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
                VStack(alignment: .leading, spacing: 10) {
                    Text(memo.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        MurmurBadge(title: "\(memo.transcriptSegments.count) segments", symbol: "text.quote")
                        MurmurBadge(title: "\(wordCount) words", symbol: "number")
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

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
}
