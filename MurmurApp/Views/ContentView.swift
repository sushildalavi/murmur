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
#if os(macOS)
        macBody
#else
        iosBody
#endif
    }

#if os(iOS)
    private var iosBody: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tab.view(container: container)
                    .tabItem {
                        Label(tab.title, systemImage: tab.symbol)
                    }
                    .tag(tab)
            }
        }
        .tint(.murmurAccent)
        .task {
            await runDemoAutomationIfNeeded()
        }
    }
#endif

#if os(macOS)
    private var macBody: some View {
        NavigationSplitView {
            List(AppTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.symbol)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .navigationTitle("Murmur")
        } detail: {
            selectedTab.view(container: container)
                .frame(minWidth: 520, minHeight: 600)
        }
        .tint(.murmurAccent)
        .frame(minWidth: 900, minHeight: 640)
        .task {
            await runDemoAutomationIfNeeded()
        }
    }
#endif

    private func runDemoAutomationIfNeeded() async {
#if DEBUG
        guard !didRunDemoAutomation else { return }
        didRunDemoAutomation = true
        guard ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_AUTOSTART"] == "1" else { return }
        selectedTab = .record
        await container.recordViewModel.startRecording()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await container.recordViewModel.stopRecording()
#endif
    }

    private static var defaultTab: AppTab {
        let processInfo = ProcessInfo.processInfo
        let demoTabArgument = Self.argumentValue(for: "--demo-tab", in: processInfo.arguments)

        switch demoTabArgument ?? processInfo.environment["MURMUR_UI_DEMO_TAB"] {
        case "library": return .library
        case "metrics": return .metrics
        case "search": return .search
        case "settings": return .settings
        default: return .record
        }
    }

    private static func argumentValue(for flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else { return nil }
        return arguments[valueIndex]
    }
}

enum AppTab: String, CaseIterable, Hashable {
    case record
    case library
    case metrics
    case search
    case settings

    var title: String {
        switch self {
        case .record: return "Record"
        case .library: return "Library"
        case .metrics: return "Metrics"
        case .search: return "Search"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .record: return "mic.fill"
        case .library: return "rectangle.stack.fill"
        case .metrics: return "chart.bar.fill"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }

    @ViewBuilder
    @MainActor
    func view(container: MurmurAppContainer) -> some View {
        switch self {
        case .record:
            RecordView(viewModel: container.recordViewModel)
        case .library:
            LibraryView(viewModel: container.libraryViewModel)
        case .metrics:
            MetricsView(viewModel: container.metricsViewModel)
        case .search:
            SearchView(memoStore: container.memoStore)
        case .settings:
            SettingsView(viewModel: container.settingsViewModel)
        }
    }
}
