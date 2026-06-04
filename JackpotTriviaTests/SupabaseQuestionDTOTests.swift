//
//  SupabaseQuestionDTOTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class SupabaseQuestionDTOTests: XCTestCase {
    func testDecodesNestedQuestionRow() throws {
        let json = """
        [{
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "catalog_slug": "gk-capital-france",
          "question_text": "What is the capital of France?",
          "question_type": "multipleChoice",
          "difficulty": "easy",
          "correct_answer_index": 2,
          "status": "approved",
          "categories": { "name": "General Knowledge" },
          "question_answers": [
            { "sort_index": 0, "answer_text": "Berlin" },
            { "sort_index": 1, "answer_text": "Madrid" },
            { "sort_index": 2, "answer_text": "Paris" },
            { "sort_index": 3, "answer_text": "Rome" }
          ]
        }]
        """.data(using: .utf8)!

        let rows = try JSONDecoder().decode([SupabaseQuestionRow].self, from: json)
        let question = try XCTUnwrap(rows.first?.toTriviaQuestion())

        XCTAssertEqual(question.catalogID, "gk-capital-france")
        XCTAssertEqual(question.category, "General Knowledge")
        XCTAssertEqual(question.correctIndex, 2)
        XCTAssertEqual(question.answers[2], "Paris")
        XCTAssertEqual(question.status, .approved)
    }
}
