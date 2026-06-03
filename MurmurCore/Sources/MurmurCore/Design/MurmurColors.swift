import SwiftUI

public extension Color {
    /// The single brand accent used across every Murmur surface.
    ///
    /// Murmur intentionally ships one accent color. Hierarchy is carried by
    /// typography, spacing, and the system's semantic colors rather than by a
    /// palette of competing hues, which keeps the UI legible in both light and
    /// dark appearances.
    static let murmurAccent = Color(red: 0.35, green: 0.34, blue: 0.83)

    /// A warm tone reserved exclusively for the recording state, matching the
    /// platform convention that "red means recording."
    static let murmurRecording = Color(red: 0.90, green: 0.26, blue: 0.24)
}
