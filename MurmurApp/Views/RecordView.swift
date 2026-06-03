import SwiftUI
import MurmurCore

@MainActor
struct RecordView: View {
    @State private var viewModel: RecordViewModel

    init(viewModel: RecordViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MurmurScreenBackground()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        header

                        MurmurPanel(tint: .murmurCyan.opacity(0.20)) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(timeString(viewModel.elapsedSeconds))
                                            .font(.system(size: 34, weight: .bold, design: .rounded))
                                            .monospacedDigit()
                                        Text(phaseDescription)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    MurmurStatusPill(
                                        title: phaseTitle,
                                        symbol: phaseSymbol,
                                        tint: phaseTint
                                    )
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Input level")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(Int(viewModel.audioLevel * 100))%")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }

                                    AudioLevelMeterView(level: viewModel.audioLevel)
                                        .frame(height: 18)
                                }

                                Button {
                                    Task {
                                        if viewModel.phase == .recording {
                                            await viewModel.stopRecording()
                                        } else {
                                            await viewModel.startRecording()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: viewModel.phase == .recording ? "stop.fill" : "mic.fill")
                                        Text(viewModel.phase == .recording ? "Stop recording" : "Start recording")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(MurmurPrimaryButtonStyle(isDestructive: viewModel.phase == .recording))
                                .disabled(viewModel.phase == .processing)
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            MurmurPanel(tint: Color.murmurOrange.opacity(0.28)) {
                                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.orange)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        transcriptSection

                        if let savedMemo = viewModel.savedMemo {
                            NavigationLink {
                                MemoDetailView(viewModel: MemoDetailViewModel(memo: savedMemo))
                            } label: {
                                MurmurMemoRow(
                                    memo: savedMemo,
                                    snippet: savedMemo.transcriptText.isEmpty ? "Saved memo" : savedMemo.transcriptText
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Record")
            .murmurInlineTitle()
        }
    }

    @ViewBuilder
    private var header: some View {
        MurmurPanel(tint: .murmurViolet.opacity(0.22)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Murmur")
                            .font(.largeTitle.bold())
                        Text("Capture, transcribe, and save voice memos with a workflow that stays local by default.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.murmurCyan, .murmurViolet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 62, height: 62)

                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurCyan, .murmurMint, .murmurOrange, .murmurViolet])

                HStack(spacing: 10) {
                    MurmurStatusPill(title: "Local capture", symbol: "lock.shield.fill", tint: .murmurLime)
                    MurmurStatusPill(title: "Live transcript", symbol: "sparkles", tint: .murmurCyan)
                    MurmurStatusPill(title: "Encrypted sync", symbol: "server.rack", tint: .murmurOrange)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
    }

    @ViewBuilder
    private var transcriptSection: some View {
        MurmurPanel(tint: .murmurMint.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 14) {
                MurmurSectionHeader(
                    "Live transcript",
                    eyebrow: "Realtime",
                    subtitle: viewModel.liveTranscript.isEmpty ? "The transcript will appear here as you speak." : "Updated continuously while recording."
                )

                if viewModel.liveTranscript.isEmpty {
                    ContentUnavailableView(
                        "No transcript yet",
                        systemImage: "text.bubble",
                        description: Text("Start speaking and Murmur will populate the transcript here.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.liveTranscript) { segment in
                            MurmurTranscriptCard(segment: segment)
                        }
                    }
                }
            }
        }
    }

    private var phaseTitle: String {
        switch viewModel.phase {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .processing: return "Processing"
        case .saved: return "Saved"
        }
    }

    private var phaseDescription: String {
        switch viewModel.phase {
        case .idle:
            return "Tap start to begin a new memo."
        case .recording:
            return "Audio and transcript are being captured locally."
        case .processing:
            return "Finalizing your memo and writing it to the library."
        case .saved:
            return "Your latest memo is available below."
        }
    }

    private var phaseSymbol: String {
        switch viewModel.phase {
        case .idle: return "circle"
        case .recording: return "record.circle.fill"
        case .processing: return "gearshape.2.fill"
        case .saved: return "checkmark.seal.fill"
        }
    }

    private var phaseTint: Color {
        switch viewModel.phase {
        case .idle: return .murmurViolet
        case .recording: return .murmurOrange
        case .processing: return .murmurGold
        case .saved: return .murmurLime
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct AudioLevelMeterView: View {
    let level: Double

    var body: some View {
        GeometryReader { proxy in
            let count = 24
            let activeCount = Int(Double(count) * max(level, 0.02))

            HStack(spacing: 4) {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: barColors[index % barColors.count],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: barHeight(for: index, activeCount: activeCount, availableHeight: proxy.size.height))
                        .opacity(index < activeCount ? 1 : 0.18)
                        .shadow(color: barColors[index % barColors.count].first!.opacity(index < activeCount ? 0.35 : 0), radius: 4, x: 0, y: 2)
                        .animation(.spring(response: 0.25, dampingFraction: 0.78), value: level)
                }
            }
        }
    }

    private var barColors: [[Color]] {
        [
            [.murmurCyan, .murmurMint],
            [.murmurMint, .murmurLime],
            [.murmurLime, .murmurGold],
            [.murmurGold, .murmurOrange],
            [.murmurOrange, .murmurViolet]
        ]
    }

    private func barHeight(for index: Int, activeCount: Int, availableHeight: CGFloat) -> CGFloat {
        let fraction = Double(index + 1) / 24.0
        let base = availableHeight * CGFloat(0.34 + 0.56 * fraction)
        return index < activeCount ? max(6, base) : max(4, availableHeight * 0.16)
    }
}

private struct MurmurPrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                LinearGradient(
                    colors: isDestructive
                        ? [Color.murmurOrange, Color.murmurViolet]
                        : [Color.murmurCyan, Color.murmurMint, Color.murmurLime],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(configuration.isPressed ? 0.10 : 0.24), radius: 14, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
