//
//  ScoringEngineTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class ScoringEngineTests: XCTestCase {
  func testScore_wrongAnswer_returnsZero() {
    let result = ScoringEngine.score(
      isCorrect: false,
      timeRemaining: 10,
      timeLimit: 15,
      difficulty: .hard,
      streakAfterAnswer: 0
    )
    XCTAssertEqual(result.total, 0)
  }

  func testScore_correctAnswer_includesBaseAndBonuses() {
    let result = ScoringEngine.score(
      isCorrect: true,
      timeRemaining: 15,
      timeLimit: 15,
      difficulty: .medium,
      streakAfterAnswer: 3
    )
    XCTAssertEqual(result.base, 150)
    XCTAssertGreaterThan(result.timeBonus, 0)
    XCTAssertEqual(result.streakBonus, 20)
    XCTAssertEqual(result.total, result.base + result.timeBonus + result.streakBonus)
  }
}
