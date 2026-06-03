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
        return MurmurAppContainer(
            memoStore: .shared,
            audioRecorder: LiveAudioRecorder(),
            transcriber: SpeechTranscriber(),
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
}
