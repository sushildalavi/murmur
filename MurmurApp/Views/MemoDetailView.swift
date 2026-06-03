import SwiftUI
import MurmurCore

@MainActor
struct MemoDetailView: View {
    @State private var viewModel: MemoDetailViewModel

    init(viewModel: MemoDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var memo: Memo {
        viewModel.memo
    }

    private var transcriptWordCount: Int {
        memo.transcriptText.split { $0.isWhitespace || $0.isNewline }.count
    }

    var body: some View {
        ZStack {
            MurmurScreenBackground()

            ScrollView {
                LazyVStack(spacing: 18) {
                    header
                    metadata
                    transcriptSection
                    audioSection
                }
                .padding(20)
            }
        }
        .navigationTitle("Memo")
        .murmurInlineTitle()
    }

    private var header: some View {
        MurmurPanel(tint: .murmurViolet.opacity(0.20)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(memo.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(memo.createdAt.formatted(date: .complete, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.murmurViolet, .murmurCyan, .murmurOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurViolet, .murmurCyan, .murmurOrange])

                HStack(spacing: 10) {
                    MurmurStatusPill(title: "\(memo.transcriptSegments.count) segments", symbol: "text.quote", tint: .murmurCyan)
                    MurmurStatusPill(title: "\(transcriptWordCount) words", symbol: "number.circle.fill", tint: .murmurOrange)
                    MurmurStatusPill(title: "Local archive", symbol: "lock.fill", tint: .murmurLime)
                }
            }
        }
    }

    private var metadata: some View {
        MurmurPanel(tint: .murmurCyan.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 10) {
                MurmurSectionHeader("Snapshot", eyebrow: "Details", subtitle: "A compact summary of the memo and its storage path.")

                VStack(alignment: .leading, spacing: 8) {
                    Label("Audio file", systemImage: "waveform")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(memo.audioFileURL.lastPathComponent)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .foregroundStyle(.primary)
                }

                Divider().overlay(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Updated", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(memo.updatedAt.formatted(date: .complete, time: .shortened))
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var transcriptSection: some View {
        MurmurPanel(tint: .murmurOrange.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 14) {
                MurmurSectionHeader(
                    "Transcript",
                    eyebrow: "Content",
                    subtitle: memo.transcriptSegments.isEmpty ? "No transcript available for this memo." : "Each transcript segment is preserved below."
                )

                if memo.transcriptSegments.isEmpty {
                    ContentUnavailableView(
                        "No transcript available",
                        systemImage: "text.bubble",
                        description: Text("This memo may have been saved before transcription completed.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        ForEach(memo.transcriptSegments) { segment in
                            MurmurTranscriptCard(segment: segment)
                        }
                    }
                }
            }
        }
    }

    private var audioSection: some View {
        MurmurPanel(tint: .murmurViolet.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 12) {
                MurmurSectionHeader("Audio path", eyebrow: "Storage")
                Text(memo.audioFileURL.path)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
