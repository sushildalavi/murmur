import Foundation

#if canImport(AppIntents)
import AppIntents

public struct StopRecordingIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Stop Recording"
    public static var description = IntentDescription("Stop the active voice memo and save it.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            NotificationCenter.default.post(name: .murmurStopRecordingRequested, object: nil)
        }
        return .result(dialog: "Stopping the current memo.")
    }
}
#else
public struct StopRecordingIntent: Sendable {
    public init() {}
}
#endif
