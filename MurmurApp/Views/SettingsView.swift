import SwiftUI

@MainActor
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Privacy") {
                Text("Raw audio, transcripts, summaries, and action items never leave the device in plaintext.")
                Toggle("Privacy mode", isOn: $viewModel.isPrivacyModeEnabled)
            }

            Section("Encryption") {
                Text(viewModel.keyStatus)
            }
        }
        .navigationTitle("Settings")
    }
}
