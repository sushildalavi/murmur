import Foundation
import MurmurCore

@MainActor
final class MurmurWatchAppContainer {
    let recordViewModel: WatchRecordViewModel

    init(recordViewModel: WatchRecordViewModel) {
        self.recordViewModel = recordViewModel
    }

    static func live() -> MurmurWatchAppContainer {
        MurmurWatchAppContainer(
            recordViewModel: WatchRecordViewModel(
                recorder: LiveAudioRecorder(),
                transcriber: SpeechTranscriber(),
                memoStore: .shared,
                recordingDirectoryProvider: WatchRecordViewModel.defaultRecordingDirectory,
                uuidProvider: UUID.init,
                dateProvider: Date.init,
                localeProvider: { Locale.current }
            )
        )
    }
}
