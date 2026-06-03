import AppIntents
import MurmurCore

/// Registers Murmur's App Intents with Siri and the Shortcuts app. Discovered
/// automatically by the system because it lives in the app target.
struct MurmurShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "Start a \(.applicationName) memo",
                "Record with \(.applicationName)"
            ],
            shortTitle: "Start Recording",
            systemImageName: "mic.fill"
        )
        AppShortcut(
            intent: StopRecordingIntent(),
            phrases: [
                "Stop the memo in \(.applicationName)",
                "End recording with \(.applicationName)"
            ],
            shortTitle: "Stop Recording",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: SearchMemosIntent(),
            phrases: [
                "Search \(.applicationName)",
                "Find a memo in \(.applicationName)"
            ],
            shortTitle: "Search Memos",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: AskMemosIntent(),
            phrases: [
                "Ask \(.applicationName) what I said about rent",
                "What did I say about \(.applicationName)?",
                "Ask \(.applicationName) about my memos"
            ],
            shortTitle: "Ask Memos",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: SummarizeLatestMemoIntent(),
            phrases: [
                "Summarize my latest memo in \(.applicationName)",
                "Give me the latest memo summary in \(.applicationName)"
            ],
            shortTitle: "Summarize Latest",
            systemImageName: "text.justify"
        )
        AppShortcut(
            intent: ExtractActionItemsIntent(),
            phrases: [
                "Extract action items from a memo in \(.applicationName)",
                "What tasks did I mention in \(.applicationName)?"
            ],
            shortTitle: "Action Items",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: SyncMemosIntent(),
            phrases: [
                "Sync my memos in \(.applicationName)",
                "Back up \(.applicationName)"
            ],
            shortTitle: "Sync Memos",
            systemImageName: "arrow.triangle.2.circlepath"
        )
        AppShortcut(
            intent: DeleteMemoIntent(),
            phrases: [
                "Delete a memo in \(.applicationName)",
                "Remove a memo from \(.applicationName)"
            ],
            shortTitle: "Delete Memo",
            systemImageName: "trash"
        )
    }
}
