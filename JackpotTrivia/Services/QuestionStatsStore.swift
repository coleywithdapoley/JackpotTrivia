//
//  QuestionStatsStore.swift
//  JackpotTrivia
//
//  Per-question play aggregates until Phase 3 syncs to Supabase.
//

import Foundation

enum QuestionStatsStore {
    private static let key = "jackpotTrivia.questions.stats"

    static func recordAnswer(
        catalogID: String,
        isCorrect: Bool,
        timedOut: Bool
    ) {
        var stats = loadAll()
        var entry = stats[catalogID] ?? QuestionAggregateStats()
        entry.timesShown += 1
        if timedOut {
            entry.timesTimedOut += 1
        } else if isCorrect {
            entry.timesCorrect += 1
        } else {
            entry.timesIncorrect += 1
        }
        stats[catalogID] = entry
        saveAll(stats)
    }

    static func incrementReportCount(catalogID: String) {
        var stats = loadAll()
        var entry = stats[catalogID] ?? QuestionAggregateStats()
        entry.reportCount += 1
        stats[catalogID] = entry
        saveAll(stats)
    }

    static func stats(for catalogID: String) -> QuestionAggregateStats {
        loadAll()[catalogID] ?? QuestionAggregateStats()
    }

    static func allStats() -> [String: QuestionAggregateStats] {
        loadAll()
    }

    /// Questions with high miss rate and enough samples for admin review.
    static func flaggedQuestionIDs(
        minimumShown: Int = 5,
        missRateThreshold: Double = 0.65
    ) -> [String] {
        loadAll()
            .filter { _, stats in
                stats.timesShown >= minimumShown && stats.missRate >= missRateThreshold
            }
            .sorted { $0.value.missRate > $1.value.missRate }
            .map(\.key)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func loadAll() -> [String: QuestionAggregateStats] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: QuestionAggregateStats].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func saveAll(_ stats: [String: QuestionAggregateStats]) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
