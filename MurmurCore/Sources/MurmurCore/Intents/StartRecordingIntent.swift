import Foundation

#if canImport(AppIntents)
import AppIntents

public struct StartRecordingIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Start Recording"
    public static var description = IntentDescription("Start recording a new voice memo.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            NotificationCenter.default.post(name: .murmurStartRecordingRequested, object: nil)
        }
        return .result(dialog: "Starting a new memo.")
    }
}
#else
public struct StartRecordingIntent: Sendable {
    public init() {}

    public var title: String { "Start Recording" }
}
#endif
