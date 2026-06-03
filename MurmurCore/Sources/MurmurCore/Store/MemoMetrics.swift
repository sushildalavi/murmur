import Foundation

public struct MemoMetrics: Codable, Equatable, Hashable, Sendable {
    public var totalMemos: Int
    public var totalTranscriptSegments: Int
    public var totalWords: Int
    public var latestMemoDate: Date?
    public var memoDaysActive: Int

    public init(
        totalMemos: Int,
        totalTranscriptSegments: Int,
        totalWords: Int,
        latestMemoDate: Date?,
        memoDaysActive: Int
    ) {
        self.totalMemos = totalMemos
        self.totalTranscriptSegments = totalTranscriptSegments
        self.totalWords = totalWords
        self.latestMemoDate = latestMemoDate
        self.memoDaysActive = memoDaysActive
    }

    public static func calculate(from memos: [Memo], calendar: Calendar = .current) -> MemoMetrics {
        let totalTranscriptSegments = memos.reduce(into: 0) { result, memo in
            result += memo.transcriptSegments.count
        }
        let totalWords = memos.reduce(into: 0) { result, memo in
            result += memo.transcriptText.split { $0.isWhitespace || $0.isNewline }.count
        }

        let latestMemoDate = memos.map(\.updatedAt).max()
        let memoDaysActive = Self.activeDays(for: memos, calendar: calendar)

        return MemoMetrics(
            totalMemos: memos.count,
            totalTranscriptSegments: totalTranscriptSegments,
            totalWords: totalWords,
            latestMemoDate: latestMemoDate,
            memoDaysActive: memoDaysActive
        )
    }

    private static func activeDays(for memos: [Memo], calendar: Calendar) -> Int {
        let days = Set(memos.map { calendar.startOfDay(for: $0.createdAt) })
        return days.count
    }
}
