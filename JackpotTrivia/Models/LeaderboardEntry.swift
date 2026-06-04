//
//  LeaderboardEntry.swift
//  JackpotTrivia
//

import Foundation

enum LeaderboardPeriod: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly
    case allTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .allTime: return "All Time"
        }
    }
}

struct LeaderboardEntry: Codable, Equatable, Identifiable {
    let id: String
    let userID: String
    let displayName: String
    let points: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let recordedAt: Date
    let roundKind: RoundKind

    var accuracyPercent: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
    }
}

struct LeaderboardStanding: Equatable, Identifiable {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var id: String { "\(rank)-\(entry.id)" }
}
