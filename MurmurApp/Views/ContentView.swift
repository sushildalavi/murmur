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
#if DEBUG
        if ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_DETAIL"] == "1" {
            DemoInsightsDetail()
        } else {
            shell
        }
#else
        shell
#endif
    }

    @ViewBuilder
    private var shell: some View {
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
        let environment = ProcessInfo.processInfo.environment

        // Capture a clean, active recording state (red stop button, live transcript).
        if environment["MURMUR_UI_DEMO_RECORDING"] == "1" {
            selectedTab = .record
            await container.recordViewModel.startRecording()
            return
        }

        // Capture the Ask (RAG) screen with a populated answer.
        if environment["MURMUR_UI_DEMO_ASK"] == "1" {
            selectedTab = .ask
            container.askViewModel.question = "What do I need to follow up on?"
            await container.askViewModel.ask()
            return
        }

        guard environment["MURMUR_UI_DEMO_AUTOSTART"] == "1" else { return }
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
        case "ask": return .ask
        case "metrics": return .metrics
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

#if DEBUG
/// Screenshot-only route: opens a memo detail and generates its insights so the
/// Insights section can be captured without navigating the live UI.
private struct DemoInsightsDetail: View {
    // Reuse the first shared demo memo so the Insights detail matches the Library.
    @State private var viewModel = MemoDetailViewModel(memo: MurmurAppContainer.demoMemos[0])

    var body: some View {
        NavigationStack {
            MemoDetailView(viewModel: viewModel)
        }
        .task { await viewModel.generateInsights() }
    }
}
#endif

enum AppTab: String, CaseIterable, Hashable {
    case record
    case library
    case ask
    case metrics
    case settings

    var title: String {
        switch self {
        case .record: return "Record"
        case .library: return "Library"
        case .ask: return "Ask"
        case .metrics: return "Metrics"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .record: return "mic.fill"
        case .library: return "rectangle.stack.fill"
        case .ask: return "sparkles"
        case .metrics: return "chart.bar.fill"
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
        case .ask:
            AskView(viewModel: container.askViewModel)
        case .metrics:
            MetricsView(viewModel: container.metricsViewModel)
        case .settings:
            SettingsView(viewModel: container.settingsViewModel)
        }
    }
}
