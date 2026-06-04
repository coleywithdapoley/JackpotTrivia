//
//  DailyJackpotPracticeSeparationTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class DailyJackpotPracticeSeparationTests: XCTestCase {
    override func tearDown() {
        DailyGameService.resetDailyCompletionForTesting()
        super.tearDown()
    }

    func testDailyAndPracticeDoNotOverlapSameDay() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let daily = DailyGameService.questionsForDailyJackpot(count: 10, date: date)
        let dailyIDs = Set(daily.map(\.catalogID))
        XCTAssertFalse(dailyIDs.isEmpty)

        let practice = QuestionBank.questions(
            for: [],
            profile: UserProfileStore.profile,
            excludingJackpotIDs: DailyGameService.todaysJackpotQuestionIDs(date: date)
        )
        let practiceIDs = Set(practice.prefix(10).map(\.catalogID))

        XCTAssertTrue(dailyIDs.isDisjoint(with: practiceIDs))
    }

    func testDailyDeckCachedForSameDay() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let first = DailyGameService.questionsForDailyJackpot(count: 5, date: date).map(\.catalogID)
        let second = DailyGameService.questionsForDailyJackpot(count: 5, date: date).map(\.catalogID)
        XCTAssertEqual(first, second)
    }
}
