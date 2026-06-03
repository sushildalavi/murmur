import SwiftUI
import MurmurCore

// MARK: - Platform-correct surface colors

extension Color {
    /// The base background for a screen, matching the system grouped table style.
    static var murmurGroupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    /// The fill for a card resting on `murmurGroupedBackground`.
    static var murmurCardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
}

// MARK: - Card container

/// A neutral content card that adapts to light and dark appearances using the
/// system's grouped-table fills. No gradients, no glass — depth comes from a
/// single hairline shadow, the way native iOS surfaces read.
struct MurmurCard<Content: View>: View {
    var spacing: CGFloat
    var padding: CGFloat
    @ViewBuilder var content: Content

    init(spacing: CGFloat = 12, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(Color.murmurCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Stat tile

/// A compact metric tile: symbol, value, caption. Monochrome accent, numeric
/// transitions, and Dynamic Type friendly.
struct MurmurStatTile: View {
    let title: String
    let value: String
    let symbol: String
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.murmurAccent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.murmurCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Memo row

/// A single library/search row. Reads like a native inset-grouped list row:
/// title, snippet, and a metadata footnote, with the accent reserved for the
/// leading glyph.
struct MurmurMemoRow: View {
    let memo: Memo
    var snippet: String

    private var wordCount: Int {
        memo.transcriptText.split { $0.isWhitespace || $0.isNewline }.count
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "waveform")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.murmurAccent)
                .frame(width: 32, height: 32)
                .background(Color.murmurAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !snippet.isEmpty {
                    Text(snippet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Text(memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                    Text("·")
                    Text("\(wordCount) words")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(memo.title). \(snippet.isEmpty ? "No snippet available." : snippet)")
    }
}

// MARK: - Transcript segment row

struct MurmurTranscriptRow: View {
    let segment: TranscriptSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(speakerLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.murmurAccent)
                Spacer()
                Text(timestamp)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(segment.text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(speakerLabel), \(timestamp). \(segment.text)")
    }

    private var timestamp: String {
        let total = Int(segment.startTime.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Turns a raw `speaker_0` token into a human label like "Speaker 1".
    private var speakerLabel: String {
        guard let index = segment.speakerID.split(separator: "_").last,
              let number = Int(index) else {
            return segment.speakerID
        }
        return "Speaker \(number + 1)"
    }
}

// MARK: - Status badge

/// A small, restrained capsule used for privacy/sync state. Tinted with the
/// accent (or a passed semantic color), never the old rainbow.
struct MurmurBadge: View {
    let title: String
    let symbol: String
    var tint: Color = .murmurAccent

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.medium))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

// MARK: - Navigation helpers

extension View {
    /// Applies the grouped background behind a scroll view on platforms that
    /// support it, and hides the default scroll background so the color shows
    /// through consistently.
    @ViewBuilder
    func murmurGroupedScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.murmurGroupedBackground.ignoresSafeArea())
    }
}
