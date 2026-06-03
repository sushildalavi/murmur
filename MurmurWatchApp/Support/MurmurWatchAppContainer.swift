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
        let demoMode = ProcessInfo.processInfo.environment["MURMUR_UI_DEMO_MODE"] == "1"
#else
        let demoMode = false
#endif
        let recorder: AudioRecorder
        let transcriber: Transcriber

        if demoMode {
            recorder = MockAudioRecorder(levelSamples: [0.2, 0.4, 0.6, 0.45], transcriptSamples: Self.demoTranscript)
            transcriber = MockTranscriber(liveSegments: Self.demoTranscript, fileSegments: Self.demoTranscript)
        } else {
            recorder = LiveAudioRecorder()
            transcriber = SpeechTranscriber()
        }

        return MurmurWatchAppContainer(
            recordViewModel: WatchRecordViewModel(
                recorder: recorder,
                transcriber: transcriber,
                memoStore: demoMode ? MemoStore() : .shared,
                recordingDirectoryProvider: WatchRecordViewModel.defaultRecordingDirectory,
                uuidProvider: UUID.init,
                dateProvider: Date.init,
                localeProvider: { Locale.current }
            )
        )
    }

#if DEBUG
    static let demoTranscript = [
        TranscriptSegment(text: "We kicked off the release and walked through the new screen.", startTime: 0, endTime: 3),
        TranscriptSegment(text: "Follow up with design on the waveform.", startTime: 3, endTime: 6)
    ]
#endif
}
