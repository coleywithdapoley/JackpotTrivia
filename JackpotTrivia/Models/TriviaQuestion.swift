//
//  TriviaQuestion.swift
//  JackpotTrivia
//

import Foundation

struct TriviaQuestion: Identifiable, Equatable {
    /// Stable slug from catalog JSON; used for analytics, reports, and retirement.
    let catalogID: String
    let category: String
    let question: String
    let answers: [String]
    let correctIndex: Int
    let content: QuestionContentFlags
    let questionType: QuestionType
    let difficulty: QuestionDifficulty
    let status: QuestionStatus
    let source: String?
    let verifiedAt: Date?
    /// Per-question cap; falls back to `difficulty.defaultTimeLimitSeconds` when nil.
    let timeLimitSeconds: Int?
    let isJackpotEligible: Bool
    let isPracticeEligible: Bool

    var id: String { catalogID }

    init(
        catalogID: String,
        category: String,
        question: String,
        answers: [String],
        correctIndex: Int,
        content: QuestionContentFlags = .standard,
        questionType: QuestionType = .multipleChoice,
        difficulty: QuestionDifficulty = .medium,
        status: QuestionStatus = .approved,
        source: String? = "human",
        verifiedAt: Date? = nil,
        timeLimitSeconds: Int? = nil,
        isJackpotEligible: Bool = true,
        isPracticeEligible: Bool = true
    ) {
        self.catalogID = catalogID
        self.category = category
        self.question = question
        self.answers = answers
        self.correctIndex = correctIndex
        self.content = content
        self.questionType = questionType
        self.difficulty = difficulty
        self.status = status
        self.source = source
        self.verifiedAt = verifiedAt
        self.timeLimitSeconds = timeLimitSeconds
        self.isJackpotEligible = isJackpotEligible
        self.isPracticeEligible = isPracticeEligible
    }

    var effectiveTimeLimitSeconds: Int {
        timeLimitSeconds ?? difficulty.defaultTimeLimitSeconds
    }
}

/// A single question ready to display, with answers optionally shuffled for the round.
struct PresentedQuestion: Identifiable, Equatable {
    let catalogID: String
    let category: String
    let question: String
    let answers: [String]
    let correctIndex: Int
    let questionType: QuestionType
    let difficulty: QuestionDifficulty
    let timeLimitSeconds: Int

    var id: String { catalogID }
}
