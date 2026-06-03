import Foundation

public struct Memo: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var audioFileURL: URL
    public var createdAt: Date
    public var updatedAt: Date
    public var transcriptSegments: [TranscriptSegment]

    public init(
        id: UUID = UUID(),
        title: String,
        audioFileURL: URL,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        transcriptSegments: [TranscriptSegment] = []
    ) {
        self.id = id
        self.title = title
        self.audioFileURL = audioFileURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.transcriptSegments = transcriptSegments
    }

    public var transcriptText: String {
        transcriptSegments.map(\.text).joined(separator: " ")
    }
}
