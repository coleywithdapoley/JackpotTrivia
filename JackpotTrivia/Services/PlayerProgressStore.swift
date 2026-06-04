//
//  PlayerProgressStore.swift
//  JackpotTrivia
//

import Foundation

struct PlayerProgress: Codable, Equatable {
    var totalCorrect: Int = 0
    var bestStreak: Int = 0
    var lifetimeXP: Int = 0

    var level: Int {
        PlayerProgress.level(forXP: lifetimeXP)
    }

    static func level(forXP xp: Int) -> Int {
        max(1, xp / 500 + 1)
    }
}

enum PlayerProgressStore {
    private static let prefix = "jackpotTrivia.progress."

    static func progress(for userID: String) -> PlayerProgress {
        guard let data = UserDefaults.standard.data(forKey: key(userID)),
              let decoded = try? JSONDecoder().decode(PlayerProgress.self, from: data) else {
            return PlayerProgress()
        }
        return decoded
    }

    static func recordRound(
        for userID: String,
        correctAnswers: Int,
        streakPeak: Int,
        xpEarned: Int
    ) {
        var stats = progress(for: userID)
        stats.totalCorrect += correctAnswers
        stats.bestStreak = max(stats.bestStreak, streakPeak)
        stats.lifetimeXP += max(0, xpEarned)
        save(stats, for: userID)
    }

    static func syncXPFromWallet(for userID: String) {
        var stats = progress(for: userID)
        stats.lifetimeXP = max(stats.lifetimeXP, PrizeWallet.lifetimePoints)
        save(stats, for: userID)
    }

    static func resetForTesting(userID: String) {
        UserDefaults.standard.removeObject(forKey: key(userID))
    }

    private static func key(_ userID: String) -> String {
        prefix + userID
    }

    private static func save(_ progress: PlayerProgress, for userID: String) {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key(userID))
        }
    }
}
