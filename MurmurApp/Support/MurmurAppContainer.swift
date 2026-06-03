import Foundation
import MurmurCore

@MainActor
final class MurmurAppContainer {
    let memoStore: MemoStore
    let audioRecorder: AudioRecorder
    let transcriber: Transcriber
    let memoSyncService: MemoSyncService?

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

    lazy var libraryViewModel: LibraryViewModel = LibraryViewModel(memoStore: memoStore)
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
            audioRecorder = MockAudioRecorder(
                levelSamples: [0.12, 0.28, 0.55, 0.42],
                transcriptSamples: [
                    TranscriptSegment(text: "Review the release checklist and confirm the dashboard is ready.", startTime: 0, endTime: 2),
                    TranscriptSegment(text: "Verify sync stays encrypted end to end before shipping.", startTime: 2, endTime: 4)
                ]
            )
            transcriber = MockTranscriber(
                liveSegments: [
                    TranscriptSegment(text: "Review the release checklist and confirm the dashboard is ready.", startTime: 0, endTime: 2),
                    TranscriptSegment(text: "Verify sync stays encrypted end to end before shipping.", startTime: 2, endTime: 4)
                ],
                fileSegments: [
                    TranscriptSegment(text: "Review the release checklist and confirm the dashboard is ready.", startTime: 0, endTime: 2),
                    TranscriptSegment(text: "Verify sync stays encrypted end to end before shipping.", startTime: 2, endTime: 4)
                ]
            )
        } else {
            audioRecorder = LiveAudioRecorder()
            transcriber = SpeechTranscriber()
        }

        let container = MurmurAppContainer(
            memoStore: .shared,
            audioRecorder: audioRecorder,
            transcriber: transcriber,
            memoSyncService: syncService
        )
        container.seedDemoDataIfNeeded()
        return container
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

    private func seedDemoDataIfNeeded() {
#if DEBUG
        guard ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_MODE"] == "1" else { return }
        guard memoStore.memos.isEmpty else { return }

        let baseURL = URL(fileURLWithPath: "/tmp/murmur-demo.m4a")
        memoStore.upsert(
            Memo(
                title: "Project kickoff",
                audioFileURL: baseURL,
                createdAt: Date(timeIntervalSince1970: 1_719_820_800),
                updatedAt: Date(timeIntervalSince1970: 1_719_820_800),
                transcriptSegments: [
                    TranscriptSegment(text: "Review the release checklist and confirm the dashboard is ready.", startTime: 0, endTime: 2),
                    TranscriptSegment(text: "Verify sync stays encrypted end to end before shipping.", startTime: 2, endTime: 4)
                ]
            )
        )
        memoStore.upsert(
            Memo(
                title: "Sync follow-up",
                audioFileURL: baseURL,
                createdAt: Date(timeIntervalSince1970: 1_719_907_200),
                updatedAt: Date(timeIntervalSince1970: 1_719_907_200),
                transcriptSegments: [
                    TranscriptSegment(text: "Watch build passes and local metrics stay up to date.", startTime: 0, endTime: 2)
                ]
            )
        )
#endif
    }
}
