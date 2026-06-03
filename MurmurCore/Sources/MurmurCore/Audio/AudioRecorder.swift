import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

public enum RecordingPhase: Equatable, Sendable {
    case idle
    case recording
    case processing
    case saved
}

public struct RecordingResult: Equatable, Sendable {
    public var fileURL: URL
    public var transcript: [TranscriptSegment]

    public init(fileURL: URL, transcript: [TranscriptSegment] = []) {
        self.fileURL = fileURL
        self.transcript = transcript
    }
}

public protocol AudioRecordingSession {
    var levelStream: AsyncStream<Double> { get }
    var transcriptStream: AsyncStream<TranscriptSegment> { get }
    func stop() async throws -> URL
}

public protocol AudioRecorder {
    func makeSession(fileURL: URL, locale: Locale, transcriber: (any Transcriber)?) async throws -> any AudioRecordingSession
}

public final class MockAudioRecordingSession: AudioRecordingSession {
    public let levelStream: AsyncStream<Double>
    public let transcriptStream: AsyncStream<TranscriptSegment>
    private let levelContinuation: AsyncStream<Double>.Continuation
    private let transcriptContinuation: AsyncStream<TranscriptSegment>.Continuation
    private let fileURL: URL
    private let levelSamples: [Double]
    private let transcriptSamples: [TranscriptSegment]

    public init(fileURL: URL, levelSamples: [Double] = [], transcriptSamples: [TranscriptSegment] = []) {
        self.fileURL = fileURL
        self.levelSamples = levelSamples
        self.transcriptSamples = transcriptSamples

        var localLevelContinuation: AsyncStream<Double>.Continuation!
        levelStream = AsyncStream { continuation in
            localLevelContinuation = continuation
        }
        levelContinuation = localLevelContinuation

        var localTranscriptContinuation: AsyncStream<TranscriptSegment>.Continuation!
        transcriptStream = AsyncStream { continuation in
            localTranscriptContinuation = continuation
        }
        transcriptContinuation = localTranscriptContinuation

        for level in levelSamples {
            levelContinuation.yield(level)
        }
        for segment in transcriptSamples {
            transcriptContinuation.yield(segment)
        }
    }

    public func stop() async throws -> URL {
        levelContinuation.finish()
        transcriptContinuation.finish()
        return fileURL
    }
}

public struct MockAudioRecorder: AudioRecorder {
    public var levelSamples: [Double]
    public var transcriptSamples: [TranscriptSegment]

    public init(levelSamples: [Double] = [], transcriptSamples: [TranscriptSegment] = []) {
        self.levelSamples = levelSamples
        self.transcriptSamples = transcriptSamples
    }

    public func makeSession(fileURL: URL, locale: Locale, transcriber: (any Transcriber)?) async throws -> any AudioRecordingSession {
        MockAudioRecordingSession(fileURL: fileURL, levelSamples: levelSamples, transcriptSamples: transcriptSamples)
    }
}

#if canImport(AVFoundation)
public final class LiveAudioRecorder: AudioRecorder {
    public init() {}

    public func makeSession(fileURL: URL, locale: Locale, transcriber: (any Transcriber)?) async throws -> any AudioRecordingSession {
        let session = LiveAudioRecordingSession(fileURL: fileURL, locale: locale, transcriber: transcriber)
        try await session.start()
        return session
    }
}

public final class LiveAudioRecordingSession: AudioRecordingSession {
    public let levelStream: AsyncStream<Double>
    public let transcriptStream: AsyncStream<TranscriptSegment>
    private let levelContinuation: AsyncStream<Double>.Continuation
    private let transcriptContinuation: AsyncStream<TranscriptSegment>.Continuation
    private let fileURL: URL
    private let transcriber: (any Transcriber)?
    private let transcriberLocale: Locale

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var liveTranscriptionSession: (any LiveTranscriptionSession)?

    public init(fileURL: URL, locale: Locale, transcriber: (any Transcriber)?) {
        self.fileURL = fileURL
        self.transcriber = transcriber
        self.transcriberLocale = locale

        var localLevelContinuation: AsyncStream<Double>.Continuation!
        levelStream = AsyncStream { continuation in
            localLevelContinuation = continuation
        }
        levelContinuation = localLevelContinuation

        var localTranscriptContinuation: AsyncStream<TranscriptSegment>.Continuation!
        transcriptStream = AsyncStream { continuation in
            localTranscriptContinuation = continuation
        }
        transcriptContinuation = localTranscriptContinuation
    }

    public func start() async throws {
        try prepareDirectories()
        try configureAudioSessionIfNeeded()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let file = try AVAudioFile(forWriting: fileURL, settings: inputFormat.settings)
        audioFile = file
        self.engine = engine

        if let transcriber {
            liveTranscriptionSession = try transcriber.makeLiveSession(locale: transcriberLocale)
            Task {
                guard let liveTranscriptionSession else { return }
                for await segment in liveTranscriptionSession.transcriptStream {
                    transcriptContinuation.yield(segment)
                }
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            guard let self else { return }
            do {
                try file.write(from: buffer)
            } catch {
                return
            }
            let level = AudioLevelMeter.normalizedLevel(from: buffer)
            self.levelContinuation.yield(level)
            self.liveTranscriptionSession?.append(buffer: buffer, at: time)
        }

        engine.prepare()
        try engine.start()
    }

    public func stop() async throws -> URL {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        liveTranscriptionSession?.finish()
        levelContinuation.finish()
        transcriptContinuation.finish()
        deactivateAudioSessionIfNeeded()
        return fileURL
    }

    private func prepareDirectories() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func configureAudioSessionIfNeeded() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
        #endif
    }

    private func deactivateAudioSessionIfNeeded() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
}
#else
public struct LiveAudioRecorder: AudioRecorder {
    public init() {}
    public func makeSession(fileURL: URL, locale: Locale, transcriber: (any Transcriber)?) async throws -> any AudioRecordingSession {
        MockAudioRecordingSession(fileURL: fileURL)
    }
}
#endif
