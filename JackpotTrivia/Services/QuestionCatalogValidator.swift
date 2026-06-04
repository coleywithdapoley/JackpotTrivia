//
//  QuestionCatalogValidator.swift
//  JackpotTrivia
//

import Foundation

enum QuestionCatalogValidationError: Equatable {
    case duplicateID(String)
    case duplicateQuestionText(String)
    case invalidCorrectIndex(catalogID: String)
    case invalidTrueFalseAnswers(catalogID: String)
    case unknownCategory(catalogID: String, category: String)
    case missingID(index: Int)
}

enum QuestionCatalogValidator {
    static func validate(
        file: QuestionCatalogFile,
        allowedCategories: [String] = AppConfig.defaultCategories
    ) -> [QuestionCatalogValidationError] {
        var errors: [QuestionCatalogValidationError] = []
        var seenIDs = Set<String>()
        var seenQuestions = Set<String>()

        for (index, item) in file.questions.enumerated() {
            let catalogID = item.id ?? "row-\(index)"
            if item.id == nil {
                errors.append(.missingID(index: index))
            }
            if !seenIDs.insert(catalogID).inserted {
                errors.append(.duplicateID(catalogID))
            }

            let normalizedQuestion = item.question.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !seenQuestions.insert(normalizedQuestion).inserted {
                errors.append(.duplicateQuestionText(catalogID))
            }

            if item.correctIndex < 0 || item.correctIndex >= item.answers.count {
                errors.append(.invalidCorrectIndex(catalogID: catalogID))
            }

            let type = QuestionType(rawValue: item.questionType ?? "")
                ?? (item.answers.count == 2 ? QuestionType.trueFalse : .multipleChoice)
            if type == .trueFalse, item.answers != QuestionType.trueFalseAnswers {
                errors.append(.invalidTrueFalseAnswers(catalogID: catalogID))
            }

            if !allowedCategories.contains(item.category) {
                errors.append(.unknownCategory(catalogID: catalogID, category: item.category))
            }
        }

        return errors
    }

    static func validateBundledCatalog() -> [QuestionCatalogValidationError] {
        guard let file = QuestionCatalogLoader.loadRawFromBundle() else { return [] }
        return validate(file: file)
    }
}
