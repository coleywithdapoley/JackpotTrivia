//
//  QuestionDifficulty.swift
//  JackpotTrivia
//

import Foundation

enum QuestionDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// Seconds allowed when `TriviaQuestion.timeLimitSeconds` is nil.
    var defaultTimeLimitSeconds: Int {
        switch self {
        case .easy: return 20
        case .medium: return 15
        case .hard: return 10
        }
    }

    /// Base points before time and streak bonuses (uniform — difficulty affects timer only).
    var basePoints: Int {
        AppConfig.pointsPerCorrectAnswer
    }
}
