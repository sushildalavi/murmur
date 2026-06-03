import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var isPrivacyModeEnabled = true
    var keyStatus: String

    init(syncStatus: String = "Local encryption enabled") {
        self.keyStatus = syncStatus
    }
}
