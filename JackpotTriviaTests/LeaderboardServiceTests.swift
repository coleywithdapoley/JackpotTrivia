//
//  LeaderboardServiceTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class LeaderboardServiceTests: XCTestCase {
  override func tearDown() {
    LeaderboardService.resetForTesting()
    super.tearDown()
  }

  func testRecordRound_appearsInDailyStandings() {
    LeaderboardService.recordRound(
      userID: "user-1",
      displayName: "Tester",
      points: 500,
      correctAnswers: 8,
      totalQuestions: 10,
      roundKind: .dailyJackpot
    )

    let standings = LeaderboardService.standings(for: .daily, currentUserID: "user-1")
    XCTAssertTrue(standings.contains(where: { $0.isCurrentUser && $0.entry.points == 500 }))
  }

  func testStandings_sortsByPointsDescending() {
    LeaderboardService.recordRound(
      userID: "a",
      displayName: "A",
      points: 100,
      correctAnswers: 5,
      totalQuestions: 10,
      roundKind: .practice
    )
    LeaderboardService.recordRound(
      userID: "b",
      displayName: "B",
      points: 900,
      correctAnswers: 9,
      totalQuestions: 10,
      roundKind: .practice
    )

    let top = LeaderboardService.standings(for: .allTime, currentUserID: nil)
    XCTAssertGreaterThanOrEqual(top.first?.entry.points ?? 0, top.dropFirst().first?.entry.points ?? 0)
  }
}
