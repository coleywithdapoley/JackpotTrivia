//
//  FeatureGatesTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class FeatureGatesTests: XCTestCase {
    func testFreeTier_limits() {
        let gates = FeatureGates(tier: .free)
        XCTAssertEqual(gates.maxQuestionsPerGame, 10)
        XCTAssertEqual(gates.maxCategoriesSelectable, 2)
        XCTAssertTrue(gates.showsAds)
    }

    func testPremiumTier_limits() {
        let gates = FeatureGates(tier: .premium)
        XCTAssertEqual(gates.maxQuestionsPerGame, 20)
        XCTAssertEqual(gates.maxCategoriesSelectable, Int.max)
        XCTAssertFalse(gates.showsAds)
    }

    func testCappedQuestions_trimsToMax() {
        let gates = FeatureGates(tier: .free)
        let questions = (0..<12).map { index in
            TriviaQuestion(
                catalogID: "test-cap-\(index)",
                category: "Science",
                question: "Q\(index)?",
                answers: ["A", "B"],
                correctIndex: 0
            )
        }
        XCTAssertEqual(gates.cappedQuestions(questions).count, 10)
    }

    func testApplyQuestionLimit_updatesSession() {
        let gates = FeatureGates(tier: .free)
        let session = GameSession()
        let questions = (0..<12).map { index in
            TriviaQuestion(
                catalogID: "test-session-cap-\(index)",
                category: "Science",
                question: "Q\(index)?",
                answers: ["A", "B"],
                correctIndex: 0
            )
        }
        session.startRound(with: questions, categories: ["Science"])
        gates.applyQuestionLimit(to: session)
        XCTAssertEqual(session.totalQuestions, 10)
    }
}
