//
//  QuestionCatalogDTO.swift
//  JackpotTrivia
//

import Foundation

struct QuestionCatalogFile: Codable {
    let version: Int
    let questions: [QuestionCatalogItem]
}

struct QuestionCatalogItem: Codable {
    let id: String?
    let category: String
    let question: String
    let answers: [String]
    let correctIndex: Int
    let questionType: String?
    let difficulty: String?
    let timeLimitSeconds: Int?
    let allowsMatureTopics: Bool?
    let isEducational: Bool?
    let isFamilySafe: Bool?
    let status: String?
    let source: String?
    let verifiedAt: String?
    let isJackpotEligible: Bool? = nil
    let isPracticeEligible: Bool? = nil

    func toTriviaQuestion() -> TriviaQuestion? {
        guard !answers.isEmpty, correctIndex >= 0, correctIndex < answers.count else { return nil }

        let catalogID = id ?? Self.fallbackID(category: category, question: question)
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
            catalogID: catalogID,
            category: category,
            question: question,
            answers: answers,
            correctIndex: correctIndex,
            content: content,
            questionType: type,
            difficulty: diff,
            status: questionStatus,
            source: source ?? "human",
            verifiedAt: verifiedDate,
            timeLimitSeconds: timeLimitSeconds,
            isJackpotEligible: isJackpotEligible ?? true,
            isPracticeEligible: isPracticeEligible ?? true
        )
    }

    private static func fallbackID(category: String, question: String) -> String {
        let prefix = category
            .lowercased()
            .replacingOccurrences(of: " & ", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let hash = abs(question.hashValue)
        return "\(prefix)-\(hash)"
    }
}
