import Foundation
import MurmurCore

@MainActor
final class MurmurAppContainer {
    let memoStore: MemoStore
    let audioRecorder: AudioRecorder
    let transcriber: Transcriber

    lazy var recordViewModel: RecordViewModel = RecordViewModel(
        recorder: audioRecorder,
        transcriber: transcriber,
        memoStore: memoStore,
        recordingDirectoryProvider: RecordViewModel.defaultRecordingDirectory,
        uuidProvider: UUID.init,
        dateProvider: Date.init,
        localeProvider: { Locale.current }
    )

    lazy var libraryViewModel: LibraryViewModel = LibraryViewModel(memoStore: memoStore)
    lazy var settingsViewModel: SettingsViewModel = SettingsViewModel()

    init(
        memoStore: MemoStore,
        audioRecorder: AudioRecorder,
        transcriber: Transcriber
    ) {
        self.memoStore = memoStore
        self.audioRecorder = audioRecorder
        self.transcriber = transcriber
    }

    static func live() -> MurmurAppContainer {
        MurmurAppContainer(
            memoStore: .shared,
            audioRecorder: LiveAudioRecorder(),
            transcriber: SpeechTranscriber()
        )
    }
}
