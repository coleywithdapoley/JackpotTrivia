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
    XCTAssertEqual(top.first?.entry.displayName, "B")
  }

  func testStandings_keepsBestScorePerUser() {
    LeaderboardService.recordRound(
      userID: "a",
      displayName: "A",
      points: 100,
      correctAnswers: 4,
      totalQuestions: 10,
      roundKind: .dailyJackpot
    )
    LeaderboardService.recordRound(
      userID: "a",
      displayName: "A",
      points: 400,
      correctAnswers: 9,
      totalQuestions: 10,
      roundKind: .practice
    )

    let standings = LeaderboardService.standings(for: .allTime, currentUserID: "a")
    XCTAssertEqual(standings.filter { $0.entry.userID == "a" }.count, 1)
    XCTAssertEqual(standings.first?.entry.points, 400)
  }

  func testStandings_doesNotInjectDemoPlayers() {
    LeaderboardService.recordRound(
      userID: "solo",
      displayName: "Solo",
      points: 250,
      correctAnswers: 6,
      totalQuestions: 10,
      roundKind: .dailyJackpot
    )

    let names = LeaderboardService.standings(for: .allTime, currentUserID: "solo").map(\.entry.displayName)
    XCTAssertEqual(names, ["Solo"])
  }
}
