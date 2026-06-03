import Foundation
import MurmurCore

@MainActor
final class MurmurWatchAppContainer {
    let recordViewModel: WatchRecordViewModel

    init(recordViewModel: WatchRecordViewModel) {
        self.recordViewModel = recordViewModel
    }

    static func live() -> MurmurWatchAppContainer {
#if DEBUG
        if ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_MODE"] == "1" {
            return MurmurWatchAppContainer(recordViewModel: makeViewModel(
                recorder: MockAudioRecorder(levelSamples: [0.2, 0.4, 0.6, 0.45], transcriptSamples: demoTranscript),
                transcriber: MockTranscriber(liveSegments: demoTranscript, fileSegments: demoTranscript),
                memoStore: MemoStore()
            ))
        }
#endif
        return MurmurWatchAppContainer(recordViewModel: makeViewModel(
            recorder: LiveAudioRecorder(),
            transcriber: SpeechTranscriber(),
            memoStore: .shared
        ))
    }

    private static func makeViewModel(
        recorder: AudioRecorder,
        transcriber: Transcriber,
        memoStore: MemoStore
    ) -> WatchRecordViewModel {
        WatchRecordViewModel(
            recorder: recorder,
            transcriber: transcriber,
            memoStore: memoStore,
            recordingDirectoryProvider: WatchRecordViewModel.defaultRecordingDirectory,
            uuidProvider: UUID.init,
            dateProvider: Date.init,
            localeProvider: { Locale.current }
        )
    }

#if DEBUG
    static let demoTranscript = [
        TranscriptSegment(text: "We kicked off the release and walked through the new screen.", startTime: 0, endTime: 3),
        TranscriptSegment(text: "Follow up with design on the waveform.", startTime: 3, endTime: 6)
    ]
#endif
}
