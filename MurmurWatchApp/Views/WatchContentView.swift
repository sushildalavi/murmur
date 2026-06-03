import SwiftUI
import MurmurCore

@MainActor
struct WatchContentView: View {
    @State private var container: MurmurWatchAppContainer

    init(container: MurmurWatchAppContainer) {
        _container = State(initialValue: container)
    }

    var body: some View {
        ZStack {
            WatchBackground()

            ScrollView {
                VStack(spacing: 12) {
                    header
                    statusCard
                    actionCard
                    transcriptCard
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
        }
    }

    private var header: some View {
        WatchCard(tint: .murmurViolet.opacity(0.18)) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.murmurCyan, .murmurViolet, .murmurOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Murmur")
                        .font(.headline.weight(.bold))
                    Text("Private memos")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeString(container.recordViewModel.elapsedSeconds))
                        .font(.system(.headline, design: .rounded).monospacedDigit())
                    Text(statusText)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                }
            }
        }
    }

    private var statusCard: some View {
        WatchCard(tint: .murmurCyan.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capture state")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(statusTitle)
                            .font(.title3.weight(.bold))
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.murmurCyan.opacity(0.20), .murmurOrange.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 52, height: 52)

                        Circle()
                            .trim(from: 0, to: max(container.recordViewModel.audioLevel, 0.05))
                            .stroke(
                                AngularGradient(
                                    colors: [.murmurCyan, .murmurMint, .murmurOrange, .murmurViolet],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 52, height: 52)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: container.recordViewModel.audioLevel)

                        Text("\(Int(container.recordViewModel.audioLevel * 100))")
                            .font(.caption2.bold())
                            .foregroundStyle(.primary)
                    }
                }

                HStack(spacing: 6) {
                    WatchChip(title: "Local", tint: .murmurLime)
                    WatchChip(title: "Live", tint: .murmurCyan)
                    WatchChip(title: "Saved", tint: .murmurOrange)
                }

                Text(statusSubtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionCard: some View {
        WatchCard(tint: actionTint.opacity(0.22)) {
            Button {
                Task {
                    if container.recordViewModel.phase == .recording {
                        await container.recordViewModel.stopRecording()
                    } else {
                        await container.recordViewModel.startRecording()
                    }
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: actionIcon)
                        .font(.title3.weight(.semibold))
                    Text(actionTitle)
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(
                LinearGradient(
                    colors: actionGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var transcriptCard: some View {
        WatchCard(tint: .murmurOrange.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Live transcript")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let savedMemo = container.recordViewModel.savedMemo {
                        Text(savedMemo.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.murmurLime)
                    }
                }

                if let lastSegment = container.recordViewModel.liveTranscript.last {
                    Text(lastSegment.text)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Speak to see the live transcript here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusTitle: String {
        switch container.recordViewModel.phase {
        case .idle: return "Ready to record"
        case .recording: return "Recording now"
        case .processing: return "Finalizing"
        case .saved: return "Saved"
        }
    }

    private var statusSubtitle: String {
        switch container.recordViewModel.phase {
        case .idle:
            return "Tap record to start a private memo."
        case .recording:
            return "Audio and transcript are captured locally."
        case .processing:
            return "Writing the memo to your archive."
        case .saved:
            return "The latest memo is ready to review."
        }
    }

    private var statusText: String {
        switch container.recordViewModel.phase {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording"
        case .processing:
            return "Processing"
        case .saved:
            return "Saved"
        }
    }

    private var statusColor: Color {
        switch container.recordViewModel.phase {
        case .idle: return .murmurViolet
        case .recording: return .murmurOrange
        case .processing: return .murmurGold
        case .saved: return .murmurLime
        }
    }

    private var actionTitle: String {
        container.recordViewModel.phase == .recording ? "Stop" : "Record"
    }

    private var actionIcon: String {
        container.recordViewModel.phase == .recording ? "stop.fill" : "mic.fill"
    }

    private var actionTint: Color {
        container.recordViewModel.phase == .recording ? .murmurOrange : .murmurCyan
    }

    private var actionGradient: [Color] {
        container.recordViewModel.phase == .recording
            ? [.murmurOrange, .murmurViolet]
            : [.murmurCyan, .murmurMint, .murmurLime]
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct WatchBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.08),
                    Color(red: 0.07, green: 0.09, blue: 0.15),
                    Color(red: 0.02, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [.murmurCyan.opacity(0.34), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 160
            )

            RadialGradient(
                colors: [.murmurOrange.opacity(0.24), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 170
            )

            RadialGradient(
                colors: [.murmurViolet.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 140
            )
        }
        .ignoresSafeArea()
    }
}

private struct WatchCard<Content: View>: View {
    var tint: Color
    let content: Content

    init(tint: Color = Color.white.opacity(0.08), @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

private struct WatchChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundStyle(.white)
            .background(tint.opacity(0.75), in: Capsule())
    }
}
