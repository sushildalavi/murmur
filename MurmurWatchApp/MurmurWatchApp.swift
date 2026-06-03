import SwiftUI

@main
struct MurmurWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView(container: .live())
        }
    }
}
