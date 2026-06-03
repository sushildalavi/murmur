import SwiftUI
import MurmurCore

struct MurmurScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.08),
                    Color(red: 0.05, green: 0.06, blue: 0.12),
                    Color(red: 0.04, green: 0.03, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.15, green: 0.94, blue: 0.88).opacity(0.36),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 500
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [
                    Color(red: 0.97, green: 0.45, blue: 0.27).opacity(0.34),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 520
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [
                    Color(red: 0.80, green: 0.32, blue: 0.95).opacity(0.20),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 430
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [
                    Color(red: 0.52, green: 0.93, blue: 0.30).opacity(0.18),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 460
            )
            .blendMode(.screen)

            Canvas { context, size in
                let spacing: CGFloat = 34
                var y: CGFloat = 0
                while y <= size.height {
                    var x: CGFloat = 0
                    while x <= size.width {
                        let diameter = (Int(x + y) % 3 == 0) ? 1.8 : 1.1
                        let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.06)))
                        x += spacing
                    }
                    y += spacing
                }
            }
            .blendMode(.overlay)
            .mask(
                LinearGradient(
                    colors: [.white.opacity(0.75), .clear],
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.86, blue: 0.98).opacity(0.26),
                            Color(red: 0.15, green: 0.94, blue: 0.88).opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: -110, y: 230)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.47, blue: 0.27).opacity(0.22),
                            Color(red: 0.80, green: 0.32, blue: 0.95).opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 220)
                .blur(radius: 28)
                .offset(x: 140, y: -180)
        }
        .ignoresSafeArea()
    }
}

struct MurmurPanel<Content: View>: View {
    var tint: Color = Color.white.opacity(0.08)
    let content: Content

    init(tint: Color = Color.white.opacity(0.08), @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.55),
                                        Color.white.opacity(0.02),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.34),
                                        tint.opacity(0.55),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.65),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 5)
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                    }
                    .shadow(color: tint.opacity(0.18), radius: 22, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 16)
            )
    }
}

struct MurmurSectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    init(_ title: String, eyebrow: String, subtitle: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(2.2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.40, green: 0.82, blue: 0.79),
                            Color(red: 0.97, green: 0.45, blue: 0.27)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MurmurStatCard: View {
    let title: String
    let value: String
    let detail: String
    var symbol: String
    var tint: Color

    var body: some View {
        MurmurPanel(tint: tint.opacity(0.30)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Image(systemName: symbol)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [
                                    tint,
                                    tint.opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    Spacer()

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tint.opacity(0.95), tint.opacity(0.08)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 18
                            )
                        )
                        .frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.82)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct MurmurMemoRow: View {
    let memo: Memo
    let snippet: String

    var body: some View {
        MurmurPanel(tint: accent.opacity(0.22)) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent,
                                accent.opacity(0.45),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(memo.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Text(memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }

                    if !snippet.isEmpty {
                        Text(snippet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 10) {
                        Label("\(memo.transcriptSegments.count) segments", systemImage: "text.quote")
                        Label("\(memo.transcriptText.split { $0.isWhitespace || $0.isNewline }.count) words", systemImage: "number")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accent: Color {
        let colors = [
            Color(red: 0.18, green: 0.86, blue: 0.98),
            Color(red: 0.98, green: 0.47, blue: 0.27),
            Color(red: 0.80, green: 0.32, blue: 0.95),
            Color(red: 0.52, green: 0.93, blue: 0.30)
        ]
        let index = abs(memo.id.hashValue) % colors.count
        return colors[index]
    }
}

struct MurmurTranscriptCard: View {
    let segment: TranscriptSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(segment.speakerID, systemImage: "person.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.40, green: 0.82, blue: 0.79),
                                Color(red: 0.80, green: 0.32, blue: 0.95)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                Text(segment.startTime, format: .number.precision(.fractionLength(1)))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(segment.text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.86, blue: 0.98).opacity(0.34),
                                    Color(red: 0.98, green: 0.47, blue: 0.27).opacity(0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct MurmurStatusPill: View {
    let title: String
    let symbol: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [
                        tint,
                        tint.opacity(0.68),
                        tint.opacity(0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

struct MurmurAccentLine: View {
    var colors: [Color]

    init(_ colors: [Color]) {
        self.colors = colors
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 999, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 4)
            .shadow(color: colors.first?.opacity(0.35) ?? .clear, radius: 8, x: 0, y: 4)
    }
}

extension View {
    @ViewBuilder
    func murmurInlineTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
