import Foundation
import XCTest
@testable import MurmurCore

final class IntentRouterTests: XCTestCase {
    func testRouterClassifiesCoreIntentFamilies() {
        let router = MemoIntentRouter()

        XCTAssertEqual(router.route(for: "Start a memo in Murmur"), .startRecording)
        XCTAssertEqual(router.route(for: "Stop the memo in Murmur"), .stopRecording)
        XCTAssertEqual(router.route(for: "Sync my memos in Murmur"), .sync)
        XCTAssertEqual(router.route(for: "What did I say about rent yesterday?"), .ask(question: "rent", dateHint: .yesterday))
        XCTAssertEqual(router.route(for: "Summarize my latest memo"), .summarizeLatest(dateHint: .latest))
        XCTAssertEqual(router.route(for: "What tasks did I mention this week?"), .extractActionItems(dateHint: .thisWeek))
        XCTAssertEqual(router.route(for: "Delete the memo about travel today"), .delete(query: "travel", dateHint: .today, requiresConfirmation: true))
    }

    func testRouterRoutesOneHundredSiriStyleUtterances() {
        let router = MemoIntentRouter()
        let topics = ["rent", "apple", "travel", "interview"]
        let dates: [(String, MemoIntentRouter.DateHint)] = [
            ("today", .today),
            ("yesterday", .yesterday),
            ("this morning", .thisMorning),
            ("this week", .thisWeek),
            ("last week", .lastWeek)
        ]

        var cases: [(String, MemoIntentRouter.Route)] = []
        for topic in topics {
            for (dateText, dateHint) in dates {
                cases.append(("find memos about \(topic) \(dateText)", .search(query: topic, dateHint: dateHint)))
                cases.append(("what did I say about \(topic) \(dateText)?", .ask(question: topic, dateHint: dateHint)))
                cases.append(("summarize my \(dateText) memo", .summarizeLatest(dateHint: dateHint)))
                cases.append(("what tasks did I mention \(dateText)?", .extractActionItems(dateHint: dateHint)))
                cases.append(("delete the memo about \(topic) \(dateText)", .delete(query: topic, dateHint: dateHint, requiresConfirmation: true)))
            }
        }

        XCTAssertEqual(cases.count, 100)

        var hits = 0
        for (utterance, expected) in cases {
            let route = router.route(for: utterance)
            if route == expected {
                hits += 1
            }
            XCTAssertEqual(route, expected, "Failed to route: \(utterance)")
        }

        let accuracy = Double(hits) / Double(cases.count)
        XCTAssertGreaterThanOrEqual(accuracy, 0.98)
    }

    func testRouterHandlesUnknownInput() {
        let route = MemoIntentRouter().route(for: "")
        XCTAssertEqual(route, .unknown(utterance: ""))
    }
}
