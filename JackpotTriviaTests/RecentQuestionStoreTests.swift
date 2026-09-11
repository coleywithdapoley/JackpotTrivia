//
//  RecentQuestionStoreTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class RecentQuestionStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        RecentQuestionStore.resetForTesting()
    }

    func testDeprioritizingRecent_prefersUnseenWhenEnoughRemain() {
        let pool = (0..<8).map { index in
            TriviaQuestion(
                catalogID: "recent-test-\(index)",
                category: "Detroit Sports",
                question: "Q\(index)?",
                answers: ["A", "B"],
                correctIndex: 0
            )
        }
        RecentQuestionStore.recordRound(catalogIDs: ["recent-test-0", "recent-test-1", "recent-test-2"])

        let filtered = RecentQuestionStore.deprioritizingRecent(pool)
        XCTAssertFalse(filtered.contains(where: { $0.catalogID == "recent-test-0" }))
        XCTAssertEqual(filtered.count, 5)
    }

    func testDeprioritizingRecent_fallsBackWhenPoolTooSmall() {
        let pool = (0..<4).map { index in
            TriviaQuestion(
                catalogID: "recent-small-\(index)",
                category: "Detroit Sports",
                question: "Q\(index)?",
                answers: ["A", "B"],
                correctIndex: 0
            )
        }
        RecentQuestionStore.recordRound(catalogIDs: ["recent-small-0", "recent-small-1", "recent-small-2"])

        let filtered = RecentQuestionStore.deprioritizingRecent(pool)
        XCTAssertEqual(filtered.count, 4)
    }
}
