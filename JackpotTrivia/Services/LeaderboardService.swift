//
//  LeaderboardService.swift
//  JackpotTrivia
//
//  Local scores plus shared Supabase standings so players can see each other.
//

import Foundation

enum LeaderboardService {
    private static let entriesKey = "jackpotTrivia.leaderboard.entries"
    private static let remoteCacheKey = "jackpotTrivia.leaderboard.remoteEntries"

    private static let remoteLock = NSLock()
    private static var remoteEntriesMemory: [LeaderboardEntry]?

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
        rankedStandings(
            from: combinedEntries(for: period),
            currentUserID: currentUserID,
            limit: limit
        )
    }

    static func currentUserRank(
        for period: LeaderboardPeriod,
        userID: String?
    ) -> LeaderboardStanding? {
        guard let userID else { return nil }
        return standings(for: period, currentUserID: userID).first(where: \.isCurrentUser)
    }

    static func rankedStandings(
        from entries: [LeaderboardEntry],
        currentUserID: String?,
        limit: Int = 50
    ) -> [LeaderboardStanding] {
        let bestPerUser = Dictionary(
            entries.map { ($0.userID, $0) },
            uniquingKeysWith: { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points ? lhs : rhs }
                return lhs.recordedAt >= rhs.recordedAt ? lhs : rhs
            }
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

    // MARK: - Remote

    static var usesLiveBoard: Bool { SupabaseConfig.isConfigured }

    /// Pulls everyone else's posted scores. Safe to call when offline or unconfigured.
    static func refreshRemote(accessToken: String? = SupabaseSessionStore.current?.accessToken) async {
        guard let client = SupabaseHTTPClient() else { return }

        let query = [
            URLQueryItem(
                name: "select",
                value: "id,user_id,display_name,points,correct_answers,total_questions,round_kind,play_date,recorded_at"
            ),
            URLQueryItem(name: "order", value: "points.desc"),
            URLQueryItem(name: "limit", value: "500"),
        ]

        do {
            let data = try await client.get(
                path: "/rest/v1/leaderboard_scores",
                query: query,
                accessToken: accessToken
            )
            let rows = try decodeRemoteRows(data)
            let entries = rows.compactMap(entry(from:))
            setRemoteEntries(entries)
        } catch {
            #if DEBUG
            print("[Leaderboard] Remote refresh failed: \(error.localizedDescription)")
            #endif
        }
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
        UserDefaults.standard.removeObject(forKey: remoteCacheKey)
        remoteLock.lock()
        remoteEntriesMemory = nil
        remoteLock.unlock()
    }

    private static func saveEntries(_ entries: [LeaderboardEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }

    private static func combinedEntries(for period: LeaderboardPeriod) -> [LeaderboardEntry] {
        filteredEntries(allEntries(), for: period) + filteredEntries(remoteEntries(), for: period)
    }

    private static func filteredEntries(_ entries: [LeaderboardEntry], for period: LeaderboardPeriod) -> [LeaderboardEntry] {
        let now = Date.now
        return entries.filter { entry in
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

    private static func remoteEntries() -> [LeaderboardEntry] {
        remoteLock.lock()
        if let memory = remoteEntriesMemory {
            remoteLock.unlock()
            return memory
        }
        remoteLock.unlock()

        guard let data = UserDefaults.standard.data(forKey: remoteCacheKey),
              let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        remoteLock.lock()
        remoteEntriesMemory = decoded
        remoteLock.unlock()
        return decoded
    }

    private static func setRemoteEntries(_ entries: [LeaderboardEntry]) {
        remoteLock.lock()
        remoteEntriesMemory = entries
        remoteLock.unlock()
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: remoteCacheKey)
        }
    }

    private static func decodeRemoteRows(_ data: Data) throws -> [RemoteScoreRow] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = isoDate(raw) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date \(raw)")
        }
        return try decoder.decode([RemoteScoreRow].self, from: data)
    }

    private static func entry(from row: RemoteScoreRow) -> LeaderboardEntry? {
        let kind = RoundKind(rawValue: row.roundKind) ?? .practice
        let recorded = row.recordedAt ?? playDateAsDate(row.playDate) ?? .now
        return LeaderboardEntry(
            id: row.id,
            userID: row.userID,
            displayName: row.displayName,
            points: row.points,
            correctAnswers: row.correctAnswers,
            totalQuestions: row.totalQuestions,
            recordedAt: recorded,
            roundKind: kind
        )
    }

    private static func playDateAsDate(_ key: String?) -> Date? {
        guard let key, !key.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private static func isoDate(_ raw: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: raw)
    }

    private struct RemoteScoreRow: Decodable {
        let id: String
        let userID: String
        let displayName: String
        let points: Int
        let correctAnswers: Int
        let totalQuestions: Int
        let roundKind: String
        let playDate: String?
        let recordedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case userID = "user_id"
            case displayName = "display_name"
            case points
            case correctAnswers = "correct_answers"
            case totalQuestions = "total_questions"
            case roundKind = "round_kind"
            case playDate = "play_date"
            case recordedAt = "recorded_at"
        }
    }
}
