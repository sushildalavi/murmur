import Foundation

public struct PendingMutation: Identifiable, Codable, Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case upsertMemo
        case deleteMemo
    }

    public var id: UUID
    public var kind: Kind
    public var memoID: UUID
    public var payload: Data
    public var createdAt: Date
    public var attempts: Int

    public init(
        id: UUID = UUID(),
        kind: Kind,
        memoID: UUID,
        payload: Data,
        createdAt: Date = Date(),
        attempts: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.memoID = memoID
        self.payload = payload
        self.createdAt = createdAt
        self.attempts = attempts
    }
}
