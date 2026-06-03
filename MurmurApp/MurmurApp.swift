import SwiftUI

#if os(iOS)
@main
struct MurmurApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
    }
}
#elseif os(macOS)
@main
struct MurmurMacApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
    }
}
#endif
