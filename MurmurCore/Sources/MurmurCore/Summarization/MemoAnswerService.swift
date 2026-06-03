import Foundation
#if !os(watchOS) && canImport(FoundationModels)
import FoundationModels
#endif

/// Answers natural-language questions about a memo library — a fully on-device
/// retrieval-augmented generation (RAG) pipeline.
///
/// 1. **Retrieve:** rank memos by semantic similarity to the question
///    (`SemanticMemoIndex`), falling back to keyword ranking.
/// 2. **Generate:** when Apple Intelligence is available, Apple's on-device
///    foundation model answers grounded in the retrieved memos; otherwise an
///    extractive fallback surfaces the most relevant memo.
///
/// Nothing leaves the device at any stage.
public struct MemoAnswerService: Sendable {
    public struct Answer: Equatable, Sendable {
        public let text: String
        public let sources: [Memo]
        public let usedAppleIntelligence: Bool
    }

    private let semanticIndex: SemanticMemoIndex

    public init(semanticIndex: SemanticMemoIndex) {
        self.semanticIndex = semanticIndex
    }

    public func answer(to question: String, over memos: [Memo], maxSources: Int = 3) async -> Answer {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Answer(text: "Ask a question about your memos to get started.", sources: [], usedAppleIntelligence: false)
        }

        let sources = retrieve(trimmed, over: memos, limit: maxSources)
        guard !sources.isEmpty else {
            return Answer(text: "I couldn't find anything in your memos about that.", sources: [], usedAppleIntelligence: false)
        }

        #if !os(watchOS) && canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *),
           case .available = SystemLanguageModel.default.availability,
           let generated = try? await Self.generate(question: trimmed, sources: sources) {
            return Answer(text: generated, sources: sources, usedAppleIntelligence: true)
        }
        #endif

        return Answer(text: Self.extractiveAnswer(for: sources), sources: sources, usedAppleIntelligence: false)
    }

    /// Semantic-first retrieval with a keyword fallback.
    private func retrieve(_ query: String, over memos: [Memo], limit: Int) -> [Memo] {
        if semanticIndex.isAvailable {
            let semantic = semanticIndex.rankedMemos(query, in: memos, limit: limit, threshold: 0.15)
            if !semantic.isEmpty { return semantic }
        }
        var index = MemoSearchIndex()
        for memo in memos { index.upsert(memo) }
        return Array(index.search(query).prefix(limit))
    }

    /// Grounded answer when the generative model is unavailable: the opening of
    /// the most relevant memo, attributed.
    static func extractiveAnswer(for sources: [Memo]) -> String {
        guard let top = sources.first else { return "" }
        let sentence = top.transcriptText
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? top.transcriptText
        return "From “\(top.title)”: \(sentence)."
    }
}

#if !os(watchOS) && canImport(FoundationModels)
extension MemoAnswerService {
    @available(iOS 26.0, macOS 26.0, *)
    fileprivate static func generate(question: String, sources: [Memo]) async throws -> String {
        let context = sources.enumerated()
            .map { index, memo in "[\(index + 1)] \(memo.title): \(memo.transcriptText)" }
            .joined(separator: "\n\n")

        let session = LanguageModelSession(
            instructions: """
            You answer questions using only the user's voice memos provided as context. \
            Be concise. If the memos do not contain the answer, say so plainly. \
            Never invent details that are not in the context.
            """
        )
        let response = try await session.respond(
            to: "Context memos:\n\(context)\n\nQuestion: \(question)\n\nAnswer:"
        )
        return response.content
    }
}
#endif
