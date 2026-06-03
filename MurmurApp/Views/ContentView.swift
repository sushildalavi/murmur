import SwiftUI
import MurmurCore

@MainActor
struct ContentView: View {
    @State private var container = MurmurAppContainer.live()

    var body: some View {
        TabView {
            RecordView(viewModel: container.recordViewModel)
                .tabItem {
                    Label("Record", systemImage: "waveform.circle")
                }

            LibraryView(viewModel: container.libraryViewModel)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            SearchView(memoStore: container.memoStore)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SettingsView(viewModel: container.settingsViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
