//
//  SupabaseSyncQueue.swift
//  JackpotTrivia
//

import Foundation

enum SupabaseSyncOperation: Codable, Equatable {
    case leaderboard(
        userID: String,
        displayName: String,
        points: Int,
        correctAnswers: Int,
        totalQuestions: Int,
        roundKind: String,
        playDate: String
    )
    case gameRound(
        userID: String,
        roundKind: String,
        playMode: String?,
        totalQuestions: Int,
        correctAnswers: Int,
        roundPoints: Int
    )
    case dailyCompletion(userID: String, playDate: String, pointsEarned: Int)
    case questionReport(catalogID: String, reason: String, userID: String?)
    case questionStats(
        catalogID: String,
        playDate: String,
        timesShown: Int,
        timesCorrect: Int,
        timesIncorrect: Int,
        timesTimedOut: Int,
        reportCount: Int
    )
}

enum SupabaseSyncQueue {
    private static let key = "jackpotTrivia.supabase.syncQueue"

    static func enqueue(_ operation: SupabaseSyncOperation) {
        var queue = all()
        queue.append(operation)
        save(queue)
    }

    static func all() -> [SupabaseSyncOperation] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SupabaseSyncOperation].self, from: data) else {
            return []
        }
        return decoded
    }

    static func replaceAll(_ operations: [SupabaseSyncOperation]) {
        save(operations)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func save(_ operations: [SupabaseSyncOperation]) {
        if let data = try? JSONEncoder().encode(operations) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
