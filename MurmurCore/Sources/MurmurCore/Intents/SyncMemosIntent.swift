import Foundation

#if canImport(AppIntents)
import AppIntents

public struct SyncMemosIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Sync Memos"
    public static var description = IntentDescription("Encrypt and sync your local memos when backup is configured.")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        switch await syncConfiguredMemos() {
        case .success(let count):
            let dialog: IntentDialog = count == 0 ? "No memos to sync." : "Synced \(count) memo\(count == 1 ? "" : "s")."
            return .result(value: count, dialog: dialog)
        case .failure(let message):
            let dialog: IntentDialog = "Sync failed: \(message)"
            return .result(value: 0, dialog: dialog)
        case .notConfigured:
            let dialog: IntentDialog = "Sync is not configured."
            return .result(value: 0, dialog: dialog)
        }
    }

    public enum SyncResult: Sendable {
        case success(Int)
        case failure(String)
        case notConfigured
    }

    public func syncConfiguredMemos(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        secretStore: any SecretStoring = KeychainStore()
    ) async -> SyncResult {
        guard
            let rawURL = environment["MURMUR_SYNC_URL"],
            let baseURL = URL(string: rawURL)
        else {
            return .notConfigured
        }

        let client = HTTPSyncClient(baseURL: baseURL, token: environment["MURMUR_SYNC_TOKEN"])
        let service = MemoSyncService(client: client, secretStore: secretStore)
        let memos = await MainActor.run { MemoStore.shared.memos }

        do {
            for memo in memos {
                try await service.sync(memo)
            }
            return .success(memos.count)
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
#else
public struct SyncMemosIntent: Sendable {
    public init() {}
}
#endif
