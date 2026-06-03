import SwiftUI
import MurmurCore

@MainActor
struct WatchContentView: View {
    @State private var container: MurmurWatchAppContainer

    init(container: MurmurWatchAppContainer) {
        _container = State(initialValue: container)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Murmur")
                    .font(.headline)

                Text("Privacy-first voice memos")
                    .font(.footnote)
                    .multilineTextAlignment(.center)

                Button(container.recordViewModel.phase == .recording ? "Stop" : "Record") {
                    Task {
                        if container.recordViewModel.phase == .recording {
                            await container.recordViewModel.stopRecording()
                        } else {
                            await container.recordViewModel.startRecording()
                        }
                    }
                }

                Text(timeString(container.recordViewModel.elapsedSeconds))
                    .font(.caption.monospacedDigit())

                if let savedMemo = container.recordViewModel.savedMemo {
                    Text(savedMemo.title)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }

                if let lastSegment = container.recordViewModel.liveTranscript.last {
                    Text(lastSegment.text)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
