import Foundation

public protocol DiarizationService {
    func diarize(_ segments: [TranscriptSegment]) async throws -> [TranscriptSegment]
}
