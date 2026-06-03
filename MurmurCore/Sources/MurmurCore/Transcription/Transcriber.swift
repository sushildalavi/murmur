import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

public protocol LiveTranscriptionSession {
    var transcriptStream: AsyncStream<TranscriptSegment> { get }
    func append(buffer: AVAudioPCMBuffer, at time: AVAudioTime)
    func finish()
}

public protocol Transcriber {
    func makeLiveSession(locale: Locale) throws -> any LiveTranscriptionSession
    func transcribeFile(at url: URL, locale: Locale) async throws -> [TranscriptSegment]
}

public struct EmptyLiveTranscriptionSession: LiveTranscriptionSession {
    public let transcriptStream: AsyncStream<TranscriptSegment>

    public init() {
        transcriptStream = AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func append(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {}
    public func finish() {}
}

public struct MockTranscriber: Transcriber {
    public var liveSegments: [TranscriptSegment]
    public var fileSegments: [TranscriptSegment]

    public init(liveSegments: [TranscriptSegment] = [], fileSegments: [TranscriptSegment] = []) {
        self.liveSegments = liveSegments
        self.fileSegments = fileSegments
    }

    public func makeLiveSession(locale: Locale) throws -> any LiveTranscriptionSession {
        MockLiveTranscriptionSession(segments: liveSegments)
    }

    public func transcribeFile(at url: URL, locale: Locale) async throws -> [TranscriptSegment] {
        fileSegments
    }
}

public final class MockLiveTranscriptionSession: LiveTranscriptionSession {
    public let transcriptStream: AsyncStream<TranscriptSegment>
    private let continuation: AsyncStream<TranscriptSegment>.Continuation

    public init(segments: [TranscriptSegment]) {
        var localContinuation: AsyncStream<TranscriptSegment>.Continuation!
        transcriptStream = AsyncStream { continuation in
            localContinuation = continuation
        }
        continuation = localContinuation

        for segment in segments {
            continuation.yield(segment)
        }
    }

    public func append(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {}
    public func finish() {
        continuation.finish()
    }
}

#if canImport(Speech)
import Speech

public final class SpeechTranscriber: Transcriber {
    public init() {}

    public func makeLiveSession(locale: Locale) throws -> any LiveTranscriptionSession {
        try SpeechLiveTranscriptionSession(locale: locale)
    }

    public func transcribeFile(at url: URL, locale: Locale) async throws -> [TranscriptSegment] {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            var finished = false
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    if !finished {
                        finished = true
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let result, result.isFinal else { return }
                if !finished {
                    finished = true
                    continuation.resume(returning: Self.segments(from: result.bestTranscription))
                }
            }
        }
    }

    private static func segments(from transcription: SFTranscription) -> [TranscriptSegment] {
        transcription.segments.map {
            TranscriptSegment(
                speakerID: "speaker_0",
                text: String($0.substring),
                startTime: $0.timestamp,
                endTime: $0.timestamp + $0.duration,
                confidence: Double($0.confidence)
            )
        }
    }
}

public final class SpeechLiveTranscriptionSession: LiveTranscriptionSession {
    public let transcriptStream: AsyncStream<TranscriptSegment>
    private let continuation: AsyncStream<TranscriptSegment>.Continuation
    private let recognizer: SFSpeechRecognizer
    private let request: SFSpeechAudioBufferRecognitionRequest
    private var task: SFSpeechRecognitionTask?
    private var emittedSegments: [TranscriptSegment] = []

    public init(locale: Locale) throws {
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            throw NSError(domain: "MurmurCore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition is unavailable for the current locale."])
        }

        self.recognizer = recognizer
        request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        var localContinuation: AsyncStream<TranscriptSegment>.Continuation!
        transcriptStream = AsyncStream { continuation in
            localContinuation = continuation
        }
        continuation = localContinuation

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if error != nil {
                self.continuation.finish()
                return
            }

            guard let result else { return }
            let segments = Self.segments(from: result.bestTranscription)
            let newSegments = Self.newSegments(current: segments, previous: self.emittedSegments)
            guard !newSegments.isEmpty else { return }
            self.emittedSegments = segments
            for segment in newSegments {
                self.continuation.yield(segment)
            }
        }
    }

    public func append(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        request.append(buffer)
    }

    public func finish() {
        request.endAudio()
        task?.cancel()
        continuation.finish()
    }

    private static func segments(from transcription: SFTranscription) -> [TranscriptSegment] {
        transcription.segments.map {
            TranscriptSegment(
                speakerID: "speaker_0",
                text: String($0.substring),
                startTime: $0.timestamp,
                endTime: $0.timestamp + $0.duration,
                confidence: Double($0.confidence)
            )
        }
    }

    private static func newSegments(current: [TranscriptSegment], previous: [TranscriptSegment]) -> [TranscriptSegment] {
        guard current.count > previous.count else { return [] }
        return Array(current.dropFirst(previous.count))
    }
}
#else
public final class SpeechTranscriber: Transcriber {
    public init() {}
    public func makeLiveSession(locale: Locale) throws -> any LiveTranscriptionSession { EmptyLiveTranscriptionSession() }
    public func transcribeFile(at url: URL, locale: Locale) async throws -> [TranscriptSegment] { [] }
}
#endif
