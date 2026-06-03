import Foundation
import Observation
import MurmurCore

@MainActor
@Observable
final class WatchRecordViewModel {
    var phase: RecordingPhase = .idle
    var audioLevel: Double = 0
    var elapsedSeconds: Int = 0
    var liveTranscript: [TranscriptSegment] = []
    var savedMemo: Memo?
    var errorMessage: String?

    @ObservationIgnored private let recorder: AudioRecorder
    @ObservationIgnored private let transcriber: Transcriber
    @ObservationIgnored private let memoStore: MemoStore
    @ObservationIgnored private let recordingDirectoryProvider: () -> URL
    @ObservationIgnored private let uuidProvider: () -> UUID
    @ObservationIgnored private let dateProvider: () -> Date
    @ObservationIgnored private let localeProvider: () -> Locale

    @ObservationIgnored private var currentSession: (any AudioRecordingSession)?
    @ObservationIgnored private var levelTask: Task<Void, Never>?
    @ObservationIgnored private var transcriptTask: Task<Void, Never>?
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var recordingID: UUID?
    @ObservationIgnored private var recordingStartDate: Date?

    init(
        recorder: AudioRecorder,
        transcriber: Transcriber,
        memoStore: MemoStore,
        recordingDirectoryProvider: @escaping () -> URL,
        uuidProvider: @escaping () -> UUID,
        dateProvider: @escaping () -> Date,
        localeProvider: @escaping () -> Locale
    ) {
        self.recorder = recorder
        self.transcriber = transcriber
        self.memoStore = memoStore
        self.recordingDirectoryProvider = recordingDirectoryProvider
        self.uuidProvider = uuidProvider
        self.dateProvider = dateProvider
        self.localeProvider = localeProvider
    }

    func startRecording() async {
        guard phase == .idle else { return }
        errorMessage = nil
        audioLevel = 0
        elapsedSeconds = 0
        liveTranscript.removeAll()
        savedMemo = nil

        let recordingID = uuidProvider()
        self.recordingID = recordingID
        recordingStartDate = dateProvider()

        let fileURL = Self.recordingFileURL(
            in: recordingDirectoryProvider(),
            id: recordingID,
            date: recordingStartDate ?? dateProvider()
        )

        do {
            let session = try await recorder.makeSession(fileURL: fileURL, locale: localeProvider(), transcriber: transcriber)
            currentSession = session
            phase = .recording
            observeLevelStream(session)
            observeTranscriptStream(session)
            startTimer()
            try? await Task.sleep(nanoseconds: 50_000_000)
        } catch {
            errorMessage = error.localizedDescription
            phase = .idle
        }
    }

    func stopRecording() async {
        guard phase == .recording, let session = currentSession, let recordingID, let recordingStartDate else { return }
        phase = .processing
        timerTask?.cancel()
        levelTask?.cancel()
        transcriptTask?.cancel()

        do {
            let fileURL = try await session.stop()
            let finalTranscript = try await resolveFinalTranscript(fileURL: fileURL)
            let memo = Memo(
                id: recordingID,
                title: Self.title(for: finalTranscript),
                audioFileURL: fileURL,
                createdAt: recordingStartDate,
                updatedAt: dateProvider(),
                transcriptSegments: finalTranscript.isEmpty ? liveTranscript : finalTranscript
            )
            memoStore.upsert(memo)
            savedMemo = memo
            liveTranscript = memo.transcriptSegments
            phase = .saved
        } catch {
            errorMessage = error.localizedDescription
            phase = .idle
        }

        currentSession = nil
        self.recordingID = nil
        self.recordingStartDate = nil
        elapsedSeconds = 0
        audioLevel = 0
    }

    private func resolveFinalTranscript(fileURL: URL) async throws -> [TranscriptSegment] {
        if !liveTranscript.isEmpty {
            return liveTranscript
        }

        do {
            return try await transcriber.transcribeFile(at: fileURL, locale: localeProvider())
        } catch {
            if !liveTranscript.isEmpty {
                return liveTranscript
            }
            throw error
        }
    }

    private func observeLevelStream(_ session: any AudioRecordingSession) {
        levelTask = Task { [weak self] in
            for await level in session.levelStream {
                await MainActor.run {
                    self?.audioLevel = level
                }
            }
        }
    }

    private func observeTranscriptStream(_ session: any AudioRecordingSession) {
        transcriptTask = Task { [weak self] in
            for await segment in session.transcriptStream {
                await MainActor.run {
                    guard let self else { return }
                    if !self.liveTranscript.contains(segment) {
                        self.liveTranscript.append(segment)
                    }
                }
            }
        }
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    self?.elapsedSeconds += 1
                }
            }
        }
    }

    private static func recordingFileURL(in directory: URL, id: UUID, date: Date) -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
        return directory
            .appendingPathComponent("murmur-\(timestamp)-\(id.uuidString)")
            .appendingPathExtension("m4a")
    }

    private static func title(for segments: [TranscriptSegment]) -> String {
        guard let first = segments.first?.text, !first.isEmpty else { return "New Memo" }
        return String(first.prefix(60))
    }

    static func defaultRecordingDirectory() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return baseURL.appendingPathComponent("Murmur/Recordings", isDirectory: true)
    }
}
