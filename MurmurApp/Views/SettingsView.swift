import SwiftUI

@MainActor
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MurmurScreenBackground()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        header
                        privacySection
                        encryptionSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .murmurInlineTitle()
        }
    }

    private var header: some View {
        MurmurPanel(tint: .murmurLime.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Settings")
                            .font(.largeTitle.bold())
                        Text("Controls are minimal on purpose. Murmur keeps the most important guarantees visible and explicit.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.murmurLime, .murmurOrange, .murmurViolet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurLime, .murmurCyan, .murmurOrange])

                MurmurStatusPill(
                    title: viewModel.isPrivacyModeEnabled ? "Privacy mode enabled" : "Privacy mode off",
                    symbol: viewModel.isPrivacyModeEnabled ? "lock.fill" : "lock.open.fill",
                    tint: viewModel.isPrivacyModeEnabled ? .murmurLime : .murmurOrange
                )
            }
        }
    }

    private var privacySection: some View {
        MurmurPanel(tint: .murmurCyan.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 14) {
                MurmurSectionHeader(
                    "Privacy",
                    eyebrow: "Data handling",
                    subtitle: "The app is designed to keep audio, transcripts, and summaries local by default."
                )

                Toggle("Privacy mode", isOn: $viewModel.isPrivacyModeEnabled)
                    .tint(.murmurCyan)

                Text("Raw audio, transcripts, summaries, and action items never leave the device in plaintext.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var encryptionSection: some View {
        MurmurPanel(tint: .murmurOrange.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 14) {
                MurmurSectionHeader(
                    "Encryption",
                    eyebrow: "Security",
                    subtitle: "Sync metadata is intentionally limited and the content is stored ciphertext-only."
                )

                Text(viewModel.keyStatus)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    MurmurStatusPill(title: "Encrypted", symbol: "checkmark.shield.fill", tint: .murmurLime)
                    MurmurStatusPill(title: "Local first", symbol: "internaldrive.fill", tint: .murmurCyan)
                }
            }
        }
    }
}
