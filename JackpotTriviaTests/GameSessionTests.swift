//
//  GameSessionTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class GameSessionTests: XCTestCase {
    /// Held on the test case so teardown runs before XCTest winds down task locals (avoids MainActor deinit crashes under TEST_HOST).
    private var session: GameSession!

    override func setUp() {
        super.setUp()
        session = GameSession()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
    }

    private func sampleQuestions(count: Int) -> [TriviaQuestion] {
        (0..<count).map { index in
            TriviaQuestion(
                catalogID: "test-science-\(index)",
                category: "Science",
                question: "Question \(index)?",
                answers: ["A", "B", "C", "D"],
                correctIndex: 0
            )
        }
    }

    func testIncrementCorrectAnswers_increasesScore() {
        XCTAssertEqual(session.correctAnswers, 0)

        session.incrementCorrectAnswers()
        session.incrementCorrectAnswers()

        XCTAssertEqual(session.correctAnswers, 2)
    }

    func testStartRound_setsTotalQuestionsFromList() {
        let questions = sampleQuestions(count: 4)

        session.startRound(with: questions, categories: ["Science"])

        XCTAssertEqual(session.totalQuestions, 4)
        XCTAssertEqual(session.currentRoundQuestions.count, 4)
        XCTAssertEqual(session.selectedCategories, ["Science"])
        XCTAssertEqual(session.correctAnswers, 0)
        XCTAssertEqual(session.currentQuestionIndex, 0)
    }

    func testBeginRound_usesFilteredQuestionBank() {
        session.beginRound(categories: ["Science"])

        XCTAssertGreaterThan(session.totalQuestions, 0)
        XCTAssertTrue(session.currentRoundQuestions.allSatisfy { $0.category == "Science" })
    }

    func testResetForReplay_clearsScoreAndReloadsQuestions() {
        let fixedRound = sampleQuestions(count: 3)
        session.startRound(with: fixedRound, categories: ["Science"])
        session.incrementCorrectAnswers()
        session.incrementCorrectAnswers()
        XCTAssertEqual(session.correctAnswers, 2)

        session.resetForReplay()

        XCTAssertEqual(session.correctAnswers, 0)
        XCTAssertEqual(session.totalQuestions, session.currentRoundQuestions.count)
        XCTAssertEqual(session.selectedCategories, ["Science"])
    }

    func testClearRound_resetsAllSessionFields() {
        session.startRound(with: sampleQuestions(count: 2), categories: ["History"])
        session.incrementCorrectAnswers()
        session.currentQuestionIndex = 1

        session.clearRound()

        XCTAssertTrue(session.selectedCategories.isEmpty)
        XCTAssertTrue(session.currentRoundQuestions.isEmpty)
        XCTAssertEqual(session.totalQuestions, 0)
        XCTAssertEqual(session.correctAnswers, 0)
        XCTAssertEqual(session.currentQuestionIndex, 0)
    }
}
