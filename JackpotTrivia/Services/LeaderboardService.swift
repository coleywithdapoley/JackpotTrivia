//
//  LeaderboardService.swift
//  JackpotTrivia
//
//  Local leaderboard until Supabase real-time ranks ship.
//

import Foundation

enum LeaderboardService {
    private static let entriesKey = "jackpotTrivia.leaderboard.entries"

    // MARK: - Record

    static func recordRound(
        userID: String,
        displayName: String,
        points: Int,
        correctAnswers: Int,
        totalQuestions: Int,
        roundKind: RoundKind,
        recordedAt: Date = .now
    ) {
        guard points > 0 || roundKind == .dailyJackpot else { return }

        let entry = LeaderboardEntry(
            id: UUID().uuidString,
            userID: userID,
            displayName: displayName,
            points: points,
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            recordedAt: recordedAt,
            roundKind: roundKind
        )
        var list = allEntries()
        list.append(entry)
        saveEntries(list)
    }

    // MARK: - Query

    static func standings(
        for period: LeaderboardPeriod,
        currentUserID: String?,
        limit: Int = 50
    ) -> [LeaderboardStanding] {
        let filtered = filteredEntries(for: period)
        let merged = mergeWithDemoPlayers(real: filtered, period: period, currentUserID: currentUserID)
        let bestPerUser = Dictionary(
            merged.map { ($0.userID, $0) },
            uniquingKeysWith: { $0.points >= $1.points ? $0 : $1 }
        )
        let ranked = bestPerUser.values.sorted { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            return lhs.recordedAt > rhs.recordedAt
        }

        return ranked.prefix(limit).enumerated().map { index, entry in
            LeaderboardStanding(
                rank: index + 1,
                entry: entry,
                isCurrentUser: entry.userID == currentUserID
            )
        }
    }

    static func currentUserRank(
        for period: LeaderboardPeriod,
        userID: String?
    ) -> LeaderboardStanding? {
        guard let userID else { return nil }
        return standings(for: period, currentUserID: userID).first(where: \.isCurrentUser)
    }

    // MARK: - Persistence

    static func allEntries() -> [LeaderboardEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: entriesKey)
    }

    private static func saveEntries(_ entries: [LeaderboardEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }

    private static func filteredEntries(for period: LeaderboardPeriod) -> [LeaderboardEntry] {
        let now = Date.now
        return allEntries().filter { entry in
            switch period {
            case .daily:
                return DailyGameService.dayKey(for: entry.recordedAt) == DailyGameService.dayKey(for: now)
            case .weekly:
                return Calendar.current.isDate(entry.recordedAt, equalTo: now, toGranularity: .weekOfYear)
            case .allTime:
                return true
            }
        }
    }

    /// Seeds plausible global competition until the API backs rankings.
    private static func mergeWithDemoPlayers(
        real: [LeaderboardEntry],
        period: LeaderboardPeriod,
        currentUserID: String?
    ) -> [LeaderboardEntry] {
        let seed = period.rawValue + DailyGameService.dayKey()
        var generator = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(seed.hashValue)))
        let names = ["QuizQueen", "BrainStorm", "TriviaKing", "FactFinder", "WiseOwl", "NeonNerd", "HistoryBuff", "SwiftMind"]
        var demo: [LeaderboardEntry] = []
        for (index, name) in names.enumerated() {
            let userID = "demo-\(name.lowercased())"
            if userID == currentUserID { continue }
            let base = 900 - (index * 70) + Int.random(in: 0...120, using: &generator)
            demo.append(LeaderboardEntry(
                id: "demo-\(index)",
                userID: userID,
                displayName: name,
                points: max(100, base),
                correctAnswers: 8,
                totalQuestions: 10,
                recordedAt: .now,
                roundKind: .dailyJackpot
            ))
        }
        return real + demo
    }
}
