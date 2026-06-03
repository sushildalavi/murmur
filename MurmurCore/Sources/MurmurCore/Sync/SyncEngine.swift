import Foundation

public struct SyncEngine {
    public var pendingMutations: [PendingMutation]
    public var lastSyncDate: Date?
    private let client: any SyncClient

    public init(client: any SyncClient, pendingMutations: [PendingMutation] = [], lastSyncDate: Date? = nil) {
        self.client = client
        self.pendingMutations = pendingMutations
        self.lastSyncDate = lastSyncDate
    }

    public mutating func enqueue(_ mutation: PendingMutation) {
        pendingMutations.append(mutation)
    }

    public mutating func sync() async throws -> [SyncBlob] {
        for mutation in pendingMutations {
            switch mutation.kind {
            case .upsertMemo:
                try await client.push(
                    SyncBlob(
                        memoID: mutation.memoID,
                        ciphertext: mutation.payload,
                        createdAt: mutation.createdAt,
                        updatedAt: mutation.createdAt
                    )
                )
            case .deleteMemo:
                try await client.delete(memoID: mutation.memoID)
            }
        }

        pendingMutations.removeAll()
        let blobs = try await client.fetchChanges(since: lastSyncDate)
        lastSyncDate = Date()
        return blobs
    }
}
