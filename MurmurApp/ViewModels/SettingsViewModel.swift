import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var isPrivacyModeEnabled = true
    var keyStatus = "Local encryption enabled"
    init() {}
}
