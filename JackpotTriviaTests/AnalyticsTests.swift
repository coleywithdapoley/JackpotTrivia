//
//  AnalyticsTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class AnalyticsTests: XCTestCase {
    func testDescribe_appOpened() {
        XCTAssertEqual(
            ConsoleAnalyticsService.describe(.appOpened),
            "app_opened"
        )
    }

    func testDescribe_inviteValidated() {
        let description = ConsoleAnalyticsService.describe(
            .inviteValidated(codeLength: 10, result: .success)
        )
        XCTAssertTrue(description.contains("invite_validated"))
        XCTAssertTrue(description.contains("codeLength=10"))
        XCTAssertTrue(description.contains("result=success"))
        XCTAssertFalse(description.contains("TRIVIA"))
    }

    func testDescribe_quizCompleted() {
        let description = ConsoleAnalyticsService.describe(
            .quizCompleted(totalQuestions: 5, correctAnswers: 3)
        )
        XCTAssertEqual(
            description,
            "quiz_completed totalQuestions=5 correctAnswers=3"
        )
    }

    func testInviteAnalyticsResult_fromValidation() {
        XCTAssertEqual(InviteAnalyticsResult.from(validation: .valid), .success)
        XCTAssertEqual(InviteAnalyticsResult.from(validation: .invalid), .invalidCode)
    }
}
