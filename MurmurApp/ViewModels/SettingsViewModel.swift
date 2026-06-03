import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var isPrivacyModeEnabled = true
    init() {}
}
