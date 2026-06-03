import SwiftUI

#if os(iOS)
@main
struct MurmurApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#elseif os(macOS)
@main
struct MurmurMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            MurmurCommands()
        }
    }
}
#endif
