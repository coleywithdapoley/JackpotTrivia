//
//  QuestionStats.swift
//  JackpotTrivia
//

import Foundation

struct QuestionAggregateStats: Codable, Equatable {
    var timesShown: Int = 0
    var timesCorrect: Int = 0
    var timesIncorrect: Int = 0
    var timesTimedOut: Int = 0
    var reportCount: Int = 0

    var missRate: Double {
        guard timesShown > 0 else { return 0 }
        return Double(timesIncorrect + timesTimedOut) / Double(timesShown)
    }

    var accuracyRate: Double {
        guard timesShown > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesShown)
    }
}
