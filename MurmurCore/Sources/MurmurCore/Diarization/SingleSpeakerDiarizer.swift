import Foundation

public struct SingleSpeakerDiarizer: DiarizationService {
    public init() {}

    public func diarize(_ segments: [TranscriptSegment]) async throws -> [TranscriptSegment] {
        segments.map { segment in
            TranscriptSegment(
                id: segment.id,
                speakerID: "speaker_0",
                text: segment.text,
                startTime: segment.startTime,
                endTime: segment.endTime,
                confidence: segment.confidence
            )
        }
    }
}
