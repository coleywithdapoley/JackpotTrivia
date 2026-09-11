//
//  QuestionBankTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class QuestionBankTests: XCTestCase {
    override func setUp() {
        super.setUp()
        RecentQuestionStore.resetForTesting()
    }

    /// Includes mature content so category-only tests are not affected by comfort filters.
    private var openProfile: UserContentProfile {
        UserContentProfile(matureTopicsEnabled: true, familySafeMode: false, educationalOnly: false)
    }

    func testFilteredQuestions_returnsOnlyMatchingCategories() {
        let category = "Auto City"
        let autoCity = QuestionBank.filteredQuestions(for: [category])

        XCTAssertFalse(autoCity.isEmpty)
        XCTAssertTrue(autoCity.allSatisfy { $0.category == category })
    }

    func testFilteredQuestions_fallsBackToAllWhenCategoryUnknown() {
        let fallback = QuestionBank.filteredQuestions(for: ["NonexistentCategory"], profile: openProfile)

        XCTAssertEqual(Set(fallback.map(\.id)), Set(QuestionBank.allQuestions.map(\.id)))
    }

    func testFilteredQuestions_returnsAllWhenCategoriesEmpty() {
        let all = QuestionBank.filteredQuestions(for: [], profile: openProfile)

        XCTAssertEqual(all.count, QuestionBank.allQuestions.count)
    }

    func testQuestions_shufflePreservesSameQuestionIDs() {
        let categories = ["Auto City"]
        let baseline = Set(QuestionBank.filteredQuestions(for: categories).map(\.id))

        var firstRun = SeededRandomNumberGenerator(seed: 42)
        var secondRun = SeededRandomNumberGenerator(seed: 99)

        let runA = QuestionBank.questions(for: categories, profile: .default, using: &firstRun)
        let runB = QuestionBank.questions(for: categories, profile: .default, using: &secondRun)

        XCTAssertEqual(Set(runA.map(\.id)), baseline)
        XCTAssertEqual(Set(runB.map(\.id)), baseline)
        // Same question IDs each run; order may vary (see deterministic seed test below).
    }

    func testQuestions_deterministicOrderWithFixedSeed() {
        var generatorA = SeededRandomNumberGenerator(seed: 7)
        var generatorB = SeededRandomNumberGenerator(seed: 7)

        let orderedA = QuestionBank.questions(for: ["Local Legends"], profile: .default, using: &generatorA)
        let orderedB = QuestionBank.questions(for: ["Local Legends"], profile: .default, using: &generatorB)

        XCTAssertEqual(orderedA.map(\.id), orderedB.map(\.id))
    }

    func testContentFilter_familySafeExcludesMature() {
        let profile = UserContentProfile(matureTopicsEnabled: false, familySafeMode: true, educationalOnly: false)
        let filtered = QuestionBank.filteredQuestions(for: [], profile: profile)
        XCTAssertTrue(filtered.allSatisfy { !$0.content.allowsMatureTopics || $0.content.isFamilySafe })
    }

    func testPresentedQuestion_preservesCorrectAnswerAfterShuffle() {
        let question = TriviaQuestion(
            catalogID: "test-presented-shuffle",
            category: "Science",
            question: "Test?",
            answers: ["A", "B", "C", "D"],
            correctIndex: 2
        )

        let presented = QuestionBank.presentedQuestion(from: question)

        XCTAssertTrue(presented.answers.indices.contains(presented.correctIndex))
        XCTAssertEqual(presented.answers[presented.correctIndex], "C")
    }

    func testPlayableQuestions_excludesRetiredCatalogIDs() {
        QuestionRetirementStore.resetForTesting()
        let question = TriviaQuestion(
            catalogID: "retire-all-players-test",
            category: "Auto City",
            question: "Should be hidden?",
            answers: ["A", "B"],
            correctIndex: 0
        )
        XCTAssertEqual(QuestionBank.playableQuestions(from: [question]).count, 1)
        QuestionRetirementStore.retire(catalogID: "retire-all-players-test")
        XCTAssertTrue(QuestionBank.playableQuestions(from: [question]).isEmpty)
        QuestionRetirementStore.resetForTesting()
    }
}
