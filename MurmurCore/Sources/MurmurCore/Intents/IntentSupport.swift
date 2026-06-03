import Foundation

public extension Notification.Name {
    /// Posted when a "Start Recording" App Intent runs, so the app can begin a
    /// new memo. The app observes this and switches to the Record tab.
    static let murmurStartRecordingRequested = Notification.Name("com.sushildalavi.murmur.startRecordingRequested")

    /// Posted when a "Stop Recording" App Intent or command runs, so the app
    /// can finish the active memo from the current recording surface.
    static let murmurStopRecordingRequested = Notification.Name("com.sushildalavi.murmur.stopRecordingRequested")
}
