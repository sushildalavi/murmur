import Foundation
import CryptoKit

public struct MemoSyncService {
    public enum SyncError: Error {
        case missingKey
    }

    private let client: any SyncClient
    private let secretStore: any SecretStoring
    private let cryptoService: CryptoService
    private let keyIdentifier: String

    public init(
        client: any SyncClient,
        secretStore: any SecretStoring,
        cryptoService: CryptoService = CryptoService(),
        keyIdentifier: String = "murmur.sync.symmetric-key"
    ) {
        self.client = client
        self.secretStore = secretStore
        self.cryptoService = cryptoService
        self.keyIdentifier = keyIdentifier
    }

    public func sync(_ memo: Memo) async throws {
        let key = try loadOrCreateKey()
        let ciphertext = try cryptoService.seal(memo, using: key)
        let blob = SyncBlob(
            memoID: memo.id,
            ciphertext: ciphertext,
            createdAt: memo.createdAt,
            updatedAt: memo.updatedAt
        )
        try await client.push(blob)
    }

    public func fetchMemos(since date: Date? = nil) async throws -> [Memo] {
        let key = try loadOrCreateKey()
        let blobs = try await client.fetchChanges(since: date)
        return try blobs.map { try cryptoService.openMemo($0.ciphertext, using: key) }
    }

    private func loadOrCreateKey() throws -> SymmetricKey {
        if let data = try secretStore.data(for: keyIdentifier) {
            return SymmetricKey(data: data)
        }

        let key = cryptoService.makeSymmetricKey()
        let data = key.withUnsafeBytes { Data($0) }
        try secretStore.save(data, for: keyIdentifier)
        return key
    }
}
