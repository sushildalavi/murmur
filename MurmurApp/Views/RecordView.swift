import SwiftUI
import MurmurCore

@MainActor
struct RecordView: View {
    @State private var viewModel: RecordViewModel

    init(viewModel: RecordViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Murmur")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                Text(timeString(viewModel.elapsedSeconds))
                    .font(.title2.monospacedDigit())

                AudioLevelMeterView(level: viewModel.audioLevel)
                    .frame(height: 18)

                Button(viewModel.phase == .recording ? "Stop Recording" : "Start Recording") {
                    Task {
                        if viewModel.phase == .recording {
                            await viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            List {
                Section("Live Transcript") {
                    if viewModel.liveTranscript.isEmpty {
                        Text("No transcript yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.liveTranscript) { segment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(segment.speakerID)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(segment.text)
                            }
                        }
                    }
                }

                if let savedMemo = viewModel.savedMemo {
                    Section("Saved") {
                        NavigationLink(savedMemo.title) {
                            MemoDetailView(viewModel: MemoDetailViewModel(memo: savedMemo))
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct AudioLevelMeterView: View {
    let level: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width * max(level, 0.05), 8)
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.gradient)
                .frame(width: width)
                .animation(.easeInOut(duration: 0.1), value: level)
        }
    }
}
