import SwiftUI
import AVFoundation

/// Drives playback of a single recorded memo file.
@MainActor
@Observable
final class AudioPlaybackModel {
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private(set) var isAvailable = false

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var ticker: Task<Void, Never>?

    init(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return
        }
        player.prepareToPlay()
        self.player = player
        self.duration = player.duration
        self.isAvailable = true
    }

    func toggle() {
        guard let player else { return }
        player.isPlaying ? pause() : play()
    }

    func seek(toFraction fraction: Double) {
        guard let player, duration > 0 else { return }
        player.currentTime = max(0, min(1, fraction)) * duration
        currentTime = player.currentTime
    }

    private func play() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player?.play()
        isPlaying = true
        startTicker()
    }

    private func pause() {
        player?.pause()
        isPlaying = false
        ticker?.cancel()
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.isPlaying = false
                    if self.currentTime >= self.duration - 0.05 {
                        self.currentTime = 0
                    }
                    return
                }
            }
        }
    }

    deinit {
        ticker?.cancel()
    }
}

struct AudioPlayerView: View {
    @State private var model: AudioPlaybackModel

    init(url: URL) {
        _model = State(initialValue: AudioPlaybackModel(url: url))
    }

    var body: some View {
        if model.isAvailable {
            HStack(spacing: 14) {
                Button(action: model.toggle) {
                    Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Color.murmurAccent)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.isPlaying ? "Pause" : "Play")

                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .tint(Color.murmurAccent)
                    HStack {
                        Text(timeString(model.currentTime))
                        Spacer()
                        Text(timeString(model.duration))
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } else {
            Label("Audio file unavailable", systemImage: "waveform.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var progress: Double {
        model.duration > 0 ? model.currentTime / model.duration : 0
    }

    private func timeString(_ time: TimeInterval) -> String {
        let total = Int(time.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
