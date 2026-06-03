import SwiftUI

@MainActor
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Privacy Mode", isOn: $viewModel.isPrivacyModeEnabled)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Raw audio, transcripts, summaries, and action items never leave the device in plaintext.")
                }

                Section {
                    LabeledContent("Status") {
                        Text(viewModel.keyStatus)
                            .foregroundStyle(.secondary)
                    }
                    row(title: "Content", value: "Ciphertext only", symbol: "lock.fill")
                    row(title: "Speech recognition", value: "On-device when supported", symbol: "waveform.badge.mic")
                } header: {
                    Text("Encryption & Sync")
                } footer: {
                    Text("Sync transmits only encrypted blobs and minimal metadata. Nothing is readable on the server.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
        }
    }

    private func row(title: String, value: String, symbol: String) -> some View {
        LabeledContent {
            Text(value).foregroundStyle(.secondary)
        } label: {
            Label(title, systemImage: symbol)
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
