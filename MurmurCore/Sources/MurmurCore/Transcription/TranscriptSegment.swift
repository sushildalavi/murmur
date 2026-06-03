import Foundation

public struct TranscriptSegment: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var speakerID: String
    public var text: String
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    public var confidence: Double

    public init(
        id: UUID = UUID(),
        speakerID: String = "speaker_0",
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        confidence: Double = 1
    ) {
        self.id = id
        self.speakerID = speakerID
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
}
