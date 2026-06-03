import Foundation

public struct SyncBlob: Codable, Equatable, Hashable, Sendable {
    public var memoID: UUID
    public var ciphertext: Data
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        memoID: UUID,
        ciphertext: Data,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.memoID = memoID
        self.ciphertext = ciphertext
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public protocol SyncClient: Sendable {
    func fetchChanges(since date: Date?) async throws -> [SyncBlob]
    func push(_ blob: SyncBlob) async throws
    func delete(memoID: UUID) async throws
}

public actor InMemorySyncClient: SyncClient {
    private var blobsByMemoID: [UUID: SyncBlob] = [:]

    public init() {}

    public func fetchChanges(since date: Date?) async throws -> [SyncBlob] {
        blobsByMemoID.values
            .filter { blob in
                guard let date else { return true }
                return blob.updatedAt >= date
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func push(_ blob: SyncBlob) async throws {
        blobsByMemoID[blob.memoID] = blob
    }

    public func delete(memoID: UUID) async throws {
        blobsByMemoID.removeValue(forKey: memoID)
    }
}
