//
//  QuestionType.swift
//  JackpotTrivia
//

import Foundation

/// Supported question formats for Phase 1+.
enum QuestionType: String, Codable, CaseIterable, Identifiable {
    case multipleChoice
    case trueFalse

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple choice"
        case .trueFalse: return "True or false"
        }
    }

    /// Default answer options when building true/false items.
    static let trueFalseAnswers = ["True", "False"]
}
