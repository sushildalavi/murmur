import Foundation
import Observation
import MurmurCore

@MainActor
@Observable
final class AskViewModel {
    var question: String = ""
    var answer: MemoAnswerService.Answer?
    var isAnswering = false

    @ObservationIgnored private let memoStore: MemoStore
    @ObservationIgnored private let answerService: MemoAnswerService

    init(memoStore: MemoStore, answerService: MemoAnswerService) {
        self.memoStore = memoStore
        self.answerService = answerService
    }

    var hasMemos: Bool { !memoStore.memos.isEmpty }

    var canAsk: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasMemos && !isAnswering
    }

    func ask() async {
        guard canAsk else { return }
        isAnswering = true
        answer = await answerService.answer(to: question, over: memoStore.memos)
        isAnswering = false
    }
}
