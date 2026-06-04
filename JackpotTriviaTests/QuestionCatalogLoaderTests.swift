//
//  QuestionCatalogLoaderTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class QuestionCatalogLoaderTests: XCTestCase {
  func testLoadFromBundle_hasQuestions() {
    let questions = QuestionCatalogLoader.loadFromBundle()
    XCTAssertGreaterThan(questions.count, 10)
  }

  func testQuestionBank_usesCatalogWhenAvailable() {
    XCTAssertGreaterThan(QuestionBank.allQuestions.count, 10)
  }

  func testCatalog_includesTrueFalseAndMultipleChoice() {
    let types = Set(QuestionBank.allQuestions.map(\.questionType))
    XCTAssertTrue(types.contains(.multipleChoice))
    XCTAssertTrue(types.contains(.trueFalse))
  }
}
