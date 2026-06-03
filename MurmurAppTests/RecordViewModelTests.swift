import Foundation
import XCTest
@testable import MurmurMacApp
@testable import MurmurCore

@MainActor
final class RecordViewModelTests: XCTestCase {
    func testRecordingTransitionsAndDeterministicSavePath() async throws {
        let baseDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let fixedDate = ISO8601DateFormatter().date(from: "2026-06-02T20:00:00.000Z") ?? Date(timeIntervalSince1970: 1_717_000_000)
        let liveSegment = TranscriptSegment(text: "hello world", startTime: 0, endTime: 1)
        let finalSegment = TranscriptSegment(text: "hello world", startTime: 0, endTime: 1)

        let recorder = MockAudioRecorder(levelSamples: [0.2, 0.8], transcriptSamples: [liveSegment])
        let transcriber = MockTranscriber(liveSegments: [liveSegment], fileSegments: [finalSegment])
        let memoStore = MemoStore()
        let viewModel = RecordViewModel(
            recorder: recorder,
            transcriber: transcriber,
            memoStore: memoStore,
            recordingDirectoryProvider: { baseDirectory },
            uuidProvider: { fixedID },
            dateProvider: { fixedDate },
            localeProvider: { Locale(identifier: "en_US") }
        )

        await viewModel.startRecording()
        XCTAssertEqual(viewModel.phase, .recording)
        XCTAssertEqual(viewModel.audioLevel, 0.8, accuracy: 0.0001)
        XCTAssertEqual(viewModel.liveTranscript.first?.text, "hello world")

        await viewModel.stopRecording()
        XCTAssertEqual(viewModel.phase, .saved)
        XCTAssertEqual(memoStore.memos.count, 1)
        XCTAssertEqual(viewModel.savedMemo?.id, fixedID)
        XCTAssertEqual(viewModel.savedMemo?.audioFileURL.path, expectedRecordingURL(baseDirectory: baseDirectory, id: fixedID, date: fixedDate).path)
        XCTAssertEqual(viewModel.savedMemo?.transcriptSegments.first?.text, "hello world")
    }

    func testAudioLevelMeterNormalizesLevels() {
        XCTAssertEqual(AudioLevelMeter.normalizedLevel(from: -120), 0)
        XCTAssertGreaterThan(AudioLevelMeter.normalizedLevel(from: -3), 0)
        XCTAssertLessThanOrEqual(AudioLevelMeter.normalizedLevel(from: 0), 1)
    }

    private func expectedRecordingURL(baseDirectory: URL, id: UUID, date: Date) -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
        return baseDirectory
            .appendingPathComponent("murmur-")
            .appendingPathComponent("\(timestamp)-\(id.uuidString)")
            .appendingPathExtension("m4a")
    }
}
