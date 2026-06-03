import Observation
import MurmurCore

@MainActor
@Observable
final class MemoDetailViewModel {
    var memo: Memo
    var insights: MemoInsights?
    var isGenerating = false

    @ObservationIgnored private let summarizer = IntelligentSummarizer()

    init(memo: Memo) {
        self.memo = memo
    }

    var hasTranscript: Bool {
        !memo.transcriptSegments.isEmpty
    }

    /// Whether on-device Apple Intelligence can run, with a reason when it can't.
    var intelligenceStatus: IntelligentSummarizer.Status {
        summarizer.status()
    }

    func generateInsights() async {
        guard !isGenerating, hasTranscript else { return }
        isGenerating = true
        insights = await summarizer.summarize(memo.transcriptSegments)
        isGenerating = false
    }
}
