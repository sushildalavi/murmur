import SwiftUI
import MurmurCore

struct MemoDetailView: View {
    @State private var viewModel: MemoDetailViewModel

    init(viewModel: MemoDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section("Title") {
                Text(viewModel.memo.title)
            }

            Section("Transcript") {
                if viewModel.memo.transcriptSegments.isEmpty {
                    Text("No transcript available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.memo.transcriptSegments) { segment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(segment.speakerID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(segment.text)
                        }
                    }
                }
            }

            Section("Audio") {
                Text(viewModel.memo.audioFileURL.path)
                    .font(.footnote)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Memo")
    }
}
