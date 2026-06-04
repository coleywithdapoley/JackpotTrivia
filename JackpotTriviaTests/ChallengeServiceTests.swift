//
//  ChallengeServiceTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class ChallengeServiceTests: XCTestCase {
  override func tearDown() {
    ChallengeService.clearPendingChallenge()
    super.tearDown()
  }

  func testChallengeURL_roundTrips() {
    let challenge = ChallengeService.makeChallenge(
      challengerName: "Sam",
      points: 800,
      correctAnswers: 7,
      totalQuestions: 10
    )
    let url = ChallengeService.challengeURL(for: challenge)!
    let parsed = ChallengeService.parseChallenge(from: url.absoluteString)

    XCTAssertEqual(parsed?.challengerName, "Sam")
    XCTAssertEqual(parsed?.points, 800)
    XCTAssertEqual(parsed?.accuracyPercent, 70)
  }

  func testHandleIncomingURL_setsPending() {
    let url = URL(string: "jackpottrivia://challenge?from=Alex&points=1200&accuracy=90&day=2026-05-27")!
    let challenge = ChallengeService.handleIncomingURL(url)

    XCTAssertEqual(challenge?.challengerName, "Alex")
    XCTAssertEqual(ChallengeService.pendingChallenge?.points, 1200)
  }
}
