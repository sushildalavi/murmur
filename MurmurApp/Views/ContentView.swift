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
        ZStack {
            MurmurScreenBackground()

            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    tab.view(container: container)
                        .tabItem {
                            Label(tab.title, systemImage: tab.symbol)
                        }
                        .tag(tab)
                }
            }
            .tint(Color.murmurCyan)
        }
        .task {
            await runDemoAutomationIfNeeded()
        }
    }
#endif

#if os(macOS)
    private var macBody: some View {
        MurmurMacShell(container: container, selectedTab: $selectedTab)
            .frame(minWidth: 1280, minHeight: 860)
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

    private static func argumentValue(for flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }

        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return arguments[valueIndex]
    }
}

private enum AppTab: String, CaseIterable, Hashable {
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
        case .record: return "waveform.circle"
        case .library: return "books.vertical"
        case .metrics: return "chart.bar.xaxis"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        }
    }

    var eyebrow: String {
        switch self {
        case .record: return "Capture"
        case .library: return "Archive"
        case .metrics: return "Insight"
        case .search: return "Discovery"
        case .settings: return "Control"
        }
    }

    var blurb: String {
        switch self {
        case .record: return "Start a new local memo."
        case .library: return "Browse the archive."
        case .metrics: return "See final usage metrics."
        case .search: return "Find content fast."
        case .settings: return "Tune privacy and sync."
        }
    }

    var accent: Color {
        switch self {
        case .record: return .murmurOrange
        case .library: return .murmurCyan
        case .metrics: return .murmurViolet
        case .search: return .murmurLime
        case .settings: return .murmurGold
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

#if os(macOS)
private struct MurmurMacShell: View {
    @State private var sidebarSelection: AppTab
    private let container: MurmurAppContainer

    init(container: MurmurAppContainer, selectedTab: Binding<AppTab>) {
        self.container = container
        _sidebarSelection = State(initialValue: selectedTab.wrappedValue)
        _selectedTab = selectedTab
    }

    @Binding private var selectedTab: AppTab

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: sidebarSelection) { _, newValue in
            selectedTab = newValue
        }
        .onChange(of: selectedTab) { _, newValue in
            sidebarSelection = newValue
        }
    }

    private var sidebar: some View {
        ZStack {
            MurmurScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sidebarHero

                    VStack(spacing: 10) {
                        ForEach(AppTab.allCases, id: \.self) { tab in
                            Button {
                                sidebarSelection = tab
                            } label: {
                                sidebarItem(for: tab)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    sidebarStats
                }
                .padding(20)
            }
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
    }

    private var sidebarHero: some View {
        MurmurPanel(tint: sidebarSelection.accent.opacity(0.22)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Murmur")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("A vivid local-first memo workspace.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.murmurCyan, .murmurViolet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }

                MurmurAccentLine([.murmurCyan, .murmurMint, .murmurOrange, .murmurViolet])

                Text("Capture, search, and review memos in a desktop layout that feels closer to a creative studio than a utility app.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sidebarItem(for tab: AppTab) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: tab == sidebarSelection
                                ? [tab.accent, tab.accent.opacity(0.55)]
                                : [Color.white.opacity(0.10), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tab == sidebarSelection ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.eyebrow)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tab == sidebarSelection ? tab.accent : .secondary)
                    .tracking(1.4)
                Text(tab.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(tab.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tab == sidebarSelection ? .thinMaterial : .ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: tab == sidebarSelection
                                    ? [tab.accent.opacity(0.80), Color.white.opacity(0.18)]
                                    : [Color.white.opacity(0.10), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: tab == sidebarSelection ? tab.accent.opacity(0.18) : .black.opacity(0.12), radius: 14, x: 0, y: 8)
        )
    }

    private var sidebarStats: some View {
        let metrics = MemoMetrics.calculate(from: container.memoStore.memos)

        return VStack(spacing: 10) {
            MurmurStatCard(
                title: "Memos",
                value: "\(metrics.totalMemos)",
                detail: "Saved locally",
                symbol: "mic.circle.fill",
                tint: .murmurCyan
            )

            MurmurStatCard(
                title: "Words",
                value: "\(metrics.totalWords)",
                detail: "Transcript volume",
                symbol: "number.square.fill",
                tint: .murmurOrange
            )
        }
    }

    private var detail: some View {
        ZStack {
            MurmurScreenBackground()

            VStack(spacing: 18) {
                detailHeader

                selectedTab.view(container: container)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                            .shadow(color: selectedTab.accent.opacity(0.12), radius: 24, x: 0, y: 12)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .padding(.top, 18)
        }
    }

    private var detailHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [selectedTab.accent, selectedTab.accent.opacity(0.45), .murmurViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: selectedTab.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedTab.eyebrow.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(selectedTab.accent)
                Text(selectedTab.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(selectedTab.blurb)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
#endif
