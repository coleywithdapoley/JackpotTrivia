//
//  QuestionStatsStoreTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class QuestionStatsStoreTests: XCTestCase {
    override func tearDown() {
        QuestionStatsStore.resetForTesting()
        super.tearDown()
    }

    func testRecordAnswer_tracksMissRate() {
        let id = "stats-test-1"
        QuestionStatsStore.recordAnswer(catalogID: id, isCorrect: true, timedOut: false)
        QuestionStatsStore.recordAnswer(catalogID: id, isCorrect: false, timedOut: false)
        QuestionStatsStore.recordAnswer(catalogID: id, isCorrect: false, timedOut: true)

        let stats = QuestionStatsStore.stats(for: id)
        XCTAssertEqual(stats.timesShown, 3)
        XCTAssertEqual(stats.timesCorrect, 1)
        XCTAssertEqual(stats.timesIncorrect, 1)
        XCTAssertEqual(stats.timesTimedOut, 1)
        XCTAssertEqual(stats.missRate, 2.0 / 3.0, accuracy: 0.01)
    }
}
