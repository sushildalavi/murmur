import Foundation
import NaturalLanguage

/// Deterministically maps messy Siri-style utterances to memo actions.
///
/// The router is intentionally simple: tokenization + rule scoring + a small
/// date-hint parser. It does not depend on Apple Intelligence so it can be
/// tested on every host and used as the fallback path when generative routing
/// is unavailable.
public struct MemoIntentRouter: Sendable {
    public enum Route: Equatable, Sendable {
        case startRecording
        case stopRecording
        case search(query: String, dateHint: DateHint?)
        case ask(question: String, dateHint: DateHint?)
        case summarizeLatest(dateHint: DateHint?)
        case extractActionItems(dateHint: DateHint?)
        case delete(query: String, dateHint: DateHint?, requiresConfirmation: Bool)
        case sync
        case unknown(utterance: String)
    }

    public enum DateHint: String, CaseIterable, Sendable {
        case today
        case yesterday
        case thisMorning
        case thisAfternoon
        case thisWeek
        case lastWeek
        case latest
    }

    public init() {}

    public func route(for utterance: String) -> Route {
        let normalized = Self.normalize(utterance)
        guard !normalized.isEmpty else { return .unknown(utterance: utterance) }

        let dateHint = Self.dateHint(in: normalized)

        if Self.matches(normalized, phrases: [
            "stop recording",
            "stop a memo",
            "stop the memo",
            "stop memo",
            "end recording",
            "end a memo",
            "end the memo",
            "end memo",
            "pause recording",
            "pause the recording"
        ]) {
            return .stopRecording
        }
        if Self.matches(normalized, phrases: [
            "start recording",
            "start a memo",
            "start the memo",
            "start memo",
            "begin recording",
            "begin a memo",
            "begin the memo",
            "new memo",
            "create a memo",
            "record a memo",
            "record with murmur"
        ]) {
            return .startRecording
        }
        if Self.containsAny(normalized, ["sync memos", "sync my memos", "sync murmur", "sync notes", "backup memos"]) {
            return .sync
        }
        if Self.containsAny(normalized, ["summarize", "summary of", "summarise", "recap"]) {
            return .summarizeLatest(dateHint: dateHint)
        }
        if Self.containsAny(normalized, ["action items", "action item", "tasks", "todo", "to do"]) {
            return .extractActionItems(dateHint: dateHint)
        }
        if Self.containsAny(normalized, ["delete", "remove", "erase"]) {
            return .delete(
                query: Self.intentQuery(from: utterance, removing: Self.deletePrefixes, fallback: utterance),
                dateHint: dateHint,
                requiresConfirmation: true
            )
        }
        if Self.containsAny(normalized, ["ask", "what did i", "what do i", "what was said", "tell me"]) {
            return .ask(
                question: Self.intentQuery(from: utterance, removing: Self.askPrefixes, fallback: utterance),
                dateHint: dateHint
            )
        }

        return .search(
            query: Self.intentQuery(from: utterance, removing: Self.searchPrefixes, fallback: utterance),
            dateHint: dateHint
        )
    }

    public func query(from route: Route) -> String? {
        switch route {
        case .search(let query, _):
            return query
        case .ask(let question, _):
            return question
        case .delete(let query, _, _):
            return query
        case .summarizeLatest(let dateHint), .extractActionItems(let dateHint):
            return dateHint?.rawValue
        default:
            return nil
        }
    }

    private static let searchPrefixes = [
        "find memos about",
        "find memo about",
        "find notes about",
        "search memos for",
        "search for",
        "search",
        "show notes about",
        "show memos about",
        "show me memos about",
        "open memo about"
    ]

    private static let askPrefixes = [
        "ask murmur about",
        "ask murmur what i said about",
        "ask murmur what i said on",
        "ask murmur",
        "ask about",
        "what did i say about",
        "what do i know about",
        "what was said about",
        "tell me about"
    ]

    private static let deletePrefixes = [
        "delete the memo about",
        "delete memo about",
        "delete the memo from",
        "delete memo from",
        "delete",
        "remove the memo about",
        "remove memo about",
        "remove the memo from",
        "remove memo from",
        "remove"
    ]

    private static func normalize(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(_ text: String, phrases: [String]) -> Bool {
        phrases.contains(where: { text == $0 || text.hasPrefix($0 + " ") || text.contains(" " + $0 + " ") })
    }

    private static func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains(where: { text.contains($0) })
    }

    private static func intentQuery(from original: String, removing prefixes: [String], fallback: String) -> String {
        let normalized = normalize(original)
        let stripped = prefixes
            .sorted(by: { $0.count > $1.count })
            .reduce(normalized) { partial, prefix in
                guard partial.hasPrefix(prefix) else { return partial }
                let remainder = partial.dropFirst(prefix.count)
                return String(remainder).trimmingCharacters(in: .whitespacesAndNewlines)
            }

        let cleaned = normalizeQuery(stripDateHints(from: stripped))
        return cleaned.isEmpty ? fallback : cleaned
    }

    private static func stripDateHints(from text: String) -> String {
        let phrases = [
            "today", "yesterday", "this morning", "this afternoon",
            "this week", "last week", "latest", "recently", "this memo", "my latest memo"
        ]
        return phrases.reduce(text) { partial, phrase in
            partial.replacingOccurrences(of: phrase, with: "", options: [.caseInsensitive])
        }
        .replacingOccurrences(of: "  ", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeQuery(_ text: String) -> String {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range]).lowercased()
            guard token.rangeOfCharacter(from: .alphanumerics) != nil else { return true }
            tokens.append(token)
            return true
        }

        return tokens.joined(separator: " ")
    }

    private static func dateHint(in text: String) -> DateHint? {
        let hints: [(DateHint, [String])] = [
            (.today, ["today"]),
            (.yesterday, ["yesterday"]),
            (.thisMorning, ["this morning", "morning"]),
            (.thisAfternoon, ["this afternoon", "afternoon"]),
            (.thisWeek, ["this week"]),
            (.lastWeek, ["last week"]),
            (.latest, ["latest", "recent", "most recent"])
        ]
        return hints.first(where: { _, phrases in
            phrases.contains(where: { text.contains($0) })
        })?.0
    }
}
