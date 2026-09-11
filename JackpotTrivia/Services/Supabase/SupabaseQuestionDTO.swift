//
//  SupabaseQuestionDTO.swift
//  JackpotTrivia
//

import Foundation

struct SupabaseCategoryRef: Decodable {
    let name: String
}

struct SupabaseAnswerRow: Decodable {
    let sortIndex: Int
    let answerText: String

    enum CodingKeys: String, CodingKey {
        case sortIndex = "sort_index"
        case answerText = "answer_text"
    }
}

struct SupabaseQuestionRow: Decodable {
    let id: String
    let catalogSlug: String?
    let questionText: String
    let questionType: String?
    let difficulty: String?
    let timeLimitSeconds: Int?
    let correctAnswerIndex: Int
    let allowsMatureTopics: Bool?
    let isEducational: Bool?
    let isFamilySafe: Bool?
    let status: String?
    let source: String?
    let verifiedAt: String?
    let categories: SupabaseCategoryRef?
    let questionAnswers: [SupabaseAnswerRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case catalogSlug = "catalog_slug"
        case questionText = "question_text"
        case questionType = "question_type"
        case difficulty
        case timeLimitSeconds = "time_limit_seconds"
        case correctAnswerIndex = "correct_answer_index"
        case allowsMatureTopics = "allows_mature_topics"
        case isEducational = "is_educational"
        case isFamilySafe = "is_family_safe"
        case status
        case source
        case verifiedAt = "verified_at"
        case categories
        case questionAnswers = "question_answers"
    }

    func toTriviaQuestion() -> TriviaQuestion? {
        guard let answers = questionAnswers?.sorted(by: { $0.sortIndex < $1.sortIndex }).map(\.answerText),
              !answers.isEmpty,
              correctAnswerIndex >= 0,
              correctAnswerIndex < answers.count else {
            return nil
        }

        let slug = catalogSlug ?? id
        let category = categories?.name ?? (AppConfig.defaultCategories.first ?? "Auto City")
        let type = QuestionType(rawValue: questionType ?? "") ?? (answers.count == 2 ? .trueFalse : .multipleChoice)
        let diff = QuestionDifficulty(rawValue: difficulty ?? "") ?? .medium
        let content = QuestionContentFlags(
            allowsMatureTopics: allowsMatureTopics ?? false,
            isEducational: isEducational ?? true,
            isFamilySafe: isFamilySafe ?? true
        )
        let questionStatus = QuestionStatus(rawValue: status ?? "approved") ?? .approved
        let verifiedDate = verifiedAt.flatMap { ISO8601DateFormatter().date(from: $0) }

        return TriviaQuestion(
            catalogID: slug,
            category: category,
            question: questionText,
            answers: answers,
            correctIndex: Int(correctAnswerIndex),
            content: content,
            questionType: type,
            difficulty: diff,
            status: questionStatus,
            source: source ?? "remote",
            verifiedAt: verifiedDate,
            timeLimitSeconds: timeLimitSeconds,
            isJackpotEligible: true,
            isPracticeEligible: true
        )
    }
}

struct SupabaseDailyGameRow: Decodable {
    let id: String
    let playDate: String
    let dailyGameQuestions: [SupabaseDailyGameQuestionRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case playDate = "play_date"
        case dailyGameQuestions = "daily_game_questions"
    }
}

struct SupabaseDailyGameQuestionRow: Decodable {
    let sequenceIndex: Int
    let questions: SupabaseQuestionRow?

    enum CodingKeys: String, CodingKey {
        case sequenceIndex = "sequence_index"
        case questions
    }
}
