import SwiftUI
import MurmurCore

@MainActor
struct ContentView: View {
    @State private var container = MurmurAppContainer.live()
    @State private var selectedTab: AppTab
    @State private var didRunDemoAutomation = false

    init() {
        _selectedTab = State(initialValue: Self.defaultTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView(viewModel: container.recordViewModel)
                .tabItem {
                    Label("Record", systemImage: "waveform.circle")
                }
                .tag(AppTab.record)

            LibraryView(viewModel: container.libraryViewModel)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(AppTab.library)

            MetricsView(viewModel: container.metricsViewModel)
                .tabItem {
                    Label("Metrics", systemImage: "chart.bar.xaxis")
                }
                .tag(AppTab.metrics)

            SearchView(memoStore: container.memoStore)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search)

            SettingsView(viewModel: container.settingsViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .task {
            guard !didRunDemoAutomation else { return }
            didRunDemoAutomation = true
            guard ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_AUTOSTART"] == "1" else { return }
            selectedTab = .record
            await container.recordViewModel.startRecording()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await container.recordViewModel.stopRecording()
        }
    }

    private static var defaultTab: AppTab {
        switch ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_TAB"] {
        case "library":
            return .library
        case "metrics":
            return .metrics
        case "search":
            return .search
        case "settings":
            return .settings
        default:
            return .record
        }
    }
}

private enum AppTab: Hashable {
    case record
    case library
    case metrics
    case search
    case settings
}
