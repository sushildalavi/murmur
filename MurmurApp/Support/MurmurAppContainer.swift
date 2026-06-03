import Foundation
import MurmurCore

@MainActor
final class MurmurAppContainer {
    let memoStore: MemoStore
    let audioRecorder: AudioRecorder
    let transcriber: Transcriber
    let memoSyncService: MemoSyncService?

    /// Shared on-device semantic index reused by hybrid search and the RAG flow.
    let semanticIndex = SemanticMemoIndex()

    lazy var recordViewModel: RecordViewModel = RecordViewModel(
        recorder: audioRecorder,
        transcriber: transcriber,
        memoStore: memoStore,
        recordingDirectoryProvider: RecordViewModel.defaultRecordingDirectory,
        uuidProvider: UUID.init,
        dateProvider: Date.init,
        localeProvider: { Locale.current },
        syncHandler: memoSyncService.map { service in
            { memo in
                try? await service.sync(memo)
            }
        }
    )

    lazy var libraryViewModel: LibraryViewModel = LibraryViewModel(memoStore: memoStore, semanticIndex: semanticIndex)
    lazy var askViewModel: AskViewModel = AskViewModel(
        memoStore: memoStore,
        answerService: MemoAnswerService(semanticIndex: semanticIndex)
    )
    lazy var metricsViewModel: MetricsViewModel = MetricsViewModel(memoStore: memoStore)
    lazy var settingsViewModel: SettingsViewModel = SettingsViewModel(
        syncStatus: memoSyncService == nil ? "Encrypted sync disabled" : "Encrypted sync enabled"
    )

    init(
        memoStore: MemoStore,
        audioRecorder: AudioRecorder,
        transcriber: Transcriber,
        memoSyncService: MemoSyncService? = nil
    ) {
        self.memoStore = memoStore
        self.audioRecorder = audioRecorder
        self.transcriber = transcriber
        self.memoSyncService = memoSyncService
    }

    static func live() -> MurmurAppContainer {
        let syncService = Self.liveSyncService()
#if DEBUG
        let demoMode = ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_MODE"] == "1"
#else
        let demoMode = false
#endif
        let audioRecorder: AudioRecorder
        let transcriber: Transcriber

        if demoMode {
            audioRecorder = MockAudioRecorder(levelSamples: [0.18, 0.34, 0.62, 0.45], transcriptSamples: Self.demoLiveTranscript)
            transcriber = MockTranscriber(liveSegments: Self.demoLiveTranscript, fileSegments: Self.demoLiveTranscript)
        } else {
            audioRecorder = LiveAudioRecorder()
            transcriber = SpeechTranscriber()
        }

        // In demo mode use an in-memory store seeded with one coherent dataset so
        // every screen shows consistent content and captures are deterministic.
        let memoStore: MemoStore = demoMode ? MemoStore(memos: Self.demoMemos) : .shared

        return MurmurAppContainer(
            memoStore: memoStore,
            audioRecorder: audioRecorder,
            transcriber: transcriber,
            memoSyncService: syncService
        )
    }

    private static func liveSyncService() -> MemoSyncService? {
        guard
            let rawURL = ProcessInfo.processInfo.environment["MURMUR_SYNC_URL"],
            let baseURL = URL(string: rawURL)
        else {
            return nil
        }

        let client = HTTPSyncClient(baseURL: baseURL)
        return MemoSyncService(client: client, secretStore: KeychainStore())
    }

#if DEBUG
    // One coherent demo dataset, shared by every screen so screenshots and the
    // in-app demo stay consistent. Dates are relative to now so they read as recent.
    static let demoLiveTranscript = [
        TranscriptSegment(text: "We kicked off the release and walked through the new recording screen.", startTime: 0, endTime: 3),
        TranscriptSegment(text: "Follow up with design on the waveform and confirm the dark mode contrast.", startTime: 3, endTime: 6),
        TranscriptSegment(text: "Action: verify the encrypted sync stays ciphertext only before we ship.", startTime: 6, endTime: 9),
        TranscriptSegment(text: "Need to benchmark search latency and update the metrics dashboard.", startTime: 9, endTime: 12)
    ]

    static var demoMemos: [Memo] {
        let now = Date()
        let hour: TimeInterval = 3_600
        let day: TimeInterval = 86_400
        return [
            Memo(
                title: "Project kickoff",
                audioFileURL: URL(fileURLWithPath: "/tmp/murmur-demo-1.m4a"),
                createdAt: now - 2 * hour,
                updatedAt: now - 2 * hour,
                transcriptSegments: demoLiveTranscript
            ),
            Memo(
                title: "Sync follow-up",
                audioFileURL: URL(fileURLWithPath: "/tmp/murmur-demo-2.m4a"),
                createdAt: now - day,
                updatedAt: now - day,
                transcriptSegments: [
                    TranscriptSegment(text: "Verify the encrypted sync stays ciphertext only before we ship.", startTime: 0, endTime: 3)
                ]
            ),
            Memo(
                title: "Weekly metrics review",
                audioFileURL: URL(fileURLWithPath: "/tmp/murmur-demo-3.m4a"),
                createdAt: now - 3 * day,
                updatedAt: now - 3 * day,
                transcriptSegments: [
                    TranscriptSegment(text: "Review this week's usage numbers and share the metrics dashboard with the team.", startTime: 0, endTime: 4)
                ]
            )
        ]
    }
#endif
}
