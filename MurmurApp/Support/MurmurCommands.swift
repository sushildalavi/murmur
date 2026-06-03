import Foundation
import SwiftUI

#if os(macOS)
struct MurmurCommands: Commands {
    var body: some Commands {
        CommandMenu("Murmur") {
            Button("Start Recording") {
                NotificationCenter.default.post(name: .murmurStartRecordingRequested, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button("Stop Recording") {
                NotificationCenter.default.post(name: .murmurStopRecordingRequested, object: nil)
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])
        }
    }
}
#endif
