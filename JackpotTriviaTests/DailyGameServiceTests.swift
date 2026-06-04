//
//  DailyGameServiceTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class DailyGameServiceTests: XCTestCase {
  override func tearDown() {
    DailyGameService.resetDailyCompletionForTesting()
    super.tearDown()
  }

  func testQuestionsForToday_isDeterministicForSameDay() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let a = DailyGameService.questionsForToday(count: 5, date: date)
    let b = DailyGameService.questionsForToday(count: 5, date: date)
    XCTAssertEqual(a.map(\.id), b.map(\.id))
  }

  func testMarkDailyCompleted_setsFlagForToday() {
    XCTAssertFalse(DailyGameService.hasCompletedDailyToday)
    DailyGameService.markDailyCompleted()
    XCTAssertTrue(DailyGameService.hasCompletedDailyToday)
  }
}
