import Foundation

#if canImport(AppIntents)
import AppIntents

public struct StartRecordingIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Start Recording"

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}
#else
public struct StartRecordingIntent: Sendable {
    public init() {}

    public var title: String { "Start Recording" }
}
#endif
