import Foundation

public struct FluidAudioDiarizer: DiarizationService {
    public init() {}

    public func diarize(_ segments: [TranscriptSegment]) async throws -> [TranscriptSegment] {
        var diarizedSegments: [TranscriptSegment] = []
        for (index, segment) in segments.enumerated() {
            diarizedSegments.append(
                TranscriptSegment(
                    id: segment.id,
                    speakerID: "speaker_\(index % 2)",
                    text: segment.text,
                    startTime: segment.startTime,
                    endTime: segment.endTime,
                    confidence: segment.confidence
                )
            )
        }
        return diarizedSegments
    }
}
