//
//  QuestionCatalogValidationTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class QuestionCatalogValidationTests: XCTestCase {
    func testBundledCatalog_hasNoValidationErrors() {
        let errors = QuestionCatalogValidator.validateBundledCatalog()
        XCTAssertTrue(errors.isEmpty, "Validation errors: \(errors)")
    }

    func testBundledCatalog_hasAtLeastSixtyApprovedQuestions() {
        guard let file = QuestionCatalogLoader.loadRawFromBundle() else {
            XCTFail("Missing QuestionCatalog.json")
            return
        }
        let approved = file.questions.filter { ($0.status ?? "approved") == "approved" }
        XCTAssertGreaterThanOrEqual(approved.count, 60)
    }

    func testValidate_detectsDuplicateID() {
        let file = QuestionCatalogFile(
            version: 1,
            questions: [
                QuestionCatalogItem(
                    id: "dup",
                    category: "Science",
                    question: "Q1?",
                    answers: ["A", "B"],
                    correctIndex: 0,
                    questionType: "multipleChoice",
                    difficulty: "easy",
                    timeLimitSeconds: nil,
                    allowsMatureTopics: nil,
                    isEducational: nil,
                    isFamilySafe: nil,
                    status: "approved",
                    source: nil,
                    verifiedAt: nil
                ),
                QuestionCatalogItem(
                    id: "dup",
                    category: "Science",
                    question: "Q2?",
                    answers: ["A", "B"],
                    correctIndex: 0,
                    questionType: "multipleChoice",
                    difficulty: "easy",
                    timeLimitSeconds: nil,
                    allowsMatureTopics: nil,
                    isEducational: nil,
                    isFamilySafe: nil,
                    status: "approved",
                    source: nil,
                    verifiedAt: nil
                ),
            ]
        )
        let errors = QuestionCatalogValidator.validate(file: file)
        XCTAssertTrue(errors.contains(.duplicateID("dup")))
    }

    func testQuestionBank_playableExcludesRetired() {
        let id = "test-retire-filter"
        let question = TriviaQuestion(
            catalogID: id,
            category: "Science",
            question: "Retire test?",
            answers: ["A", "B"],
            correctIndex: 0
        )
        QuestionRetirementStore.retire(catalogID: id)
        let pool = QuestionBank.playableQuestions(from: [question])
        XCTAssertFalse(pool.contains { $0.catalogID == id })
        QuestionRetirementStore.unretire(catalogID: id)
    }
}
