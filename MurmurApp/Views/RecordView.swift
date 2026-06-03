import SwiftUI
import MurmurCore

@MainActor
struct RecordView: View {
    @State private var viewModel: RecordViewModel

    init(viewModel: RecordViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var isRecording: Bool { viewModel.phase == .recording }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    recordingSurface

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                    }

                    transcriptSection

                    if let savedMemo = viewModel.savedMemo {
                        savedMemoLink(savedMemo)
                    }
                }
                .padding()
            }
            .murmurGroupedScreen()
            .navigationTitle("Record")
        }
    }

    // MARK: Recording surface

    private var recordingSurface: some View {
        MurmurCard(spacing: 24, padding: 28) {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(timeString(viewModel.elapsedSeconds))
                        .font(.system(size: 52, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isRecording ? Color.murmurRecording : .primary)
                        .contentTransition(.numericText())

                    Text(phaseDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                WaveformMeter(level: viewModel.audioLevel, isActive: isRecording)
                    .frame(height: 44)

                RecordButton(isRecording: isRecording, isBusy: viewModel.phase == .processing) {
                    Task {
                        if isRecording {
                            await viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.smooth(duration: 0.25), value: viewModel.phase)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(Color.murmurRecording)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.murmurRecording.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Live transcript

    @ViewBuilder
    private var transcriptSection: some View {
        MurmurCard(spacing: 14) {
            HStack {
                Text("Live Transcript")
                    .font(.headline)
                Spacer()
                if isRecording {
                    Label("Live", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.murmurRecording)
                        .labelStyle(.titleAndIcon)
                }
            }

            if viewModel.liveTranscript.isEmpty {
                ContentUnavailableView(
                    "Nothing captured yet",
                    systemImage: "text.bubble",
                    description: Text("Start recording and your words appear here as you speak.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                ForEach(Array(viewModel.liveTranscript.enumerated()), id: \.element.id) { index, segment in
                    if index > 0 { Divider() }
                    MurmurTranscriptRow(segment: segment)
                }
            }
        }
    }

    private func savedMemoLink(_ memo: Memo) -> some View {
        NavigationLink {
            MemoDetailView(viewModel: MemoDetailViewModel(memo: memo))
        } label: {
            MurmurCard {
                HStack {
                    MurmurMemoRow(memo: memo, snippet: memo.transcriptText.isEmpty ? "Saved memo" : memo.transcriptText)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Phase copy

    private var phaseDescription: String {
        switch viewModel.phase {
        case .idle: return "Tap to start a new memo. Everything stays on device."
        case .recording: return "Recording — audio and transcript captured locally."
        case .processing: return "Saving your memo to the library…"
        case .saved: return "Saved. Your latest memo is ready below."
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Record button

private struct RecordButton: View {
    let isRecording: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.18), lineWidth: 4)
                    .frame(width: 76, height: 76)

                RoundedRectangle(cornerRadius: isRecording ? 7 : 30, style: .continuous)
                    .fill(Color.murmurRecording)
                    .frame(width: isRecording ? 30 : 60, height: isRecording ? 30 : 60)

                if isBusy {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .frame(width: 88, height: 88)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint(isRecording ? "Stops the active memo and saves it locally." : "Starts a new local voice memo.")
    }
}

// MARK: - Waveform meter

private struct WaveformMeter: View {
    let level: Double
    let isActive: Bool

    private let barCount = 27

    var body: some View {
        GeometryReader { proxy in
            let activeBars = Int(Double(barCount) * max(level, 0.02).clampedUnit)
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(Color.murmurAccent)
                        .opacity(index < activeBars ? 1 : 0.18)
                        .frame(height: barHeight(index: index, height: proxy.size.height))
                        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isActive ? 1 : 0.45)
        }
    }

    private func barHeight(index: Int, height: CGFloat) -> CGFloat {
        // Symmetric envelope: taller toward the center, short at the edges.
        let distanceFromCenter = abs(Double(index) - Double(barCount - 1) / 2)
        let envelope = 1 - (distanceFromCenter / (Double(barCount) / 2)) * 0.65
        return max(4, height * CGFloat(envelope))
    }
}

private extension Double {
    var clampedUnit: Double { Swift.max(0, Swift.min(1, self)) }
}
