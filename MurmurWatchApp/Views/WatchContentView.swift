import SwiftUI
import MurmurCore

@MainActor
struct WatchContentView: View {
    @State private var container: MurmurWatchAppContainer
    @State private var didStartDemo = false

    init(container: MurmurWatchAppContainer) {
        _container = State(initialValue: container)
    }

    private var recorder: WatchRecordViewModel { container.recordViewModel }
    private var isRecording: Bool { recorder.phase == .recording }

    var body: some View {
        VStack(spacing: 8) {
            timer
            transcript
            Spacer(minLength: 0)
            recordButton
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
        .padding(.bottom, 6)
        .navigationTitle("Murmur")
        .task {
#if DEBUG
            guard !didStartDemo,
                  ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_RECORDING"] == "1" else { return }
            didStartDemo = true
            await recorder.startRecording()
#endif
        }
    }

    private var timer: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(timeString(recorder.elapsedSeconds))
                .font(.system(size: 30, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isRecording ? Color.murmurRecording : .primary)
                .contentTransition(.numericText())
            Text(statusText)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isRecording ? Color.murmurRecording : .secondary)
            Spacer()
        }
    }

    private var recordButton: some View {
        Button {
            Task {
                if isRecording {
                    await recorder.stopRecording()
                } else {
                    await recorder.startRecording()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.22), lineWidth: 3)
                RoundedRectangle(cornerRadius: isRecording ? 5 : 22, style: .continuous)
                    .fill(Color.murmurRecording)
                    .frame(width: isRecording ? 22 : 44, height: isRecording ? 22 : 44)
                if recorder.phase == .processing {
                    ProgressView().tint(.white)
                }
            }
            .frame(width: 58, height: 58)
        }
        .buttonStyle(.plain)
        .disabled(recorder.phase == .processing)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }

    private var transcript: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Live")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if let last = recorder.liveTranscript.last {
                Text(last.text)
                    .font(.footnote)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let saved = recorder.savedMemo {
                Label(saved.title, systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.murmurAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Speak to see the transcript here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusText: String {
        switch recorder.phase {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .processing: return "Saving…"
        case .saved: return "Saved"
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
