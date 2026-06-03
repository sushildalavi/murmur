import Foundation

#if canImport(AppIntents)
import AppIntents

public struct AskMemosIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Ask Memos"
    public static var description = IntentDescription("Ask a natural-language question about your voice memos.")

    @Parameter(title: "Question")
    public var question: String

    public init() {
        question = ""
    }

    public init(question: String) {
        self.question = question
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let answer = await answer(using: MemoAnswerService(semanticIndex: SemanticMemoIndex()))
        let dialog: IntentDialog = answer.sources.isEmpty
            ? "I couldn't find anything in your memos."
            : "Answered from \(answer.sources.count) memo\(answer.sources.count == 1 ? "" : "s")."
        return .result(value: answer.text, dialog: dialog)
    }

    public func answer(using answerService: MemoAnswerService = MemoAnswerService(semanticIndex: SemanticMemoIndex())) async -> MemoAnswerService.Answer {
        let memos = await MainActor.run { MemoStore.shared.memos }
        return await answerService.answer(to: question, over: memos)
    }
}
#else
public struct AskMemosIntent: Sendable {
    public var question: String

    public init(question: String = "") {
        self.question = question
    }
}
#endif
