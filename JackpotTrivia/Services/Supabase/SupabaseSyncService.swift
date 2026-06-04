//
//  SupabaseSyncService.swift
//  JackpotTrivia
//

import Foundation

enum SupabaseSyncService {
    static func recordRound(
        user: AuthUser,
        points: Int,
        correctAnswers: Int,
        totalQuestions: Int,
        roundKind: RoundKind,
        playMode: GamePlayMode?
    ) {
        guard SupabaseConfig.isConfigured else { return }

        let playDate = DailyGameService.dayKey()
        SupabaseSyncQueue.enqueue(.leaderboard(
            userID: user.id,
            displayName: user.displayName ?? user.email,
            points: points,
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            roundKind: roundKind.rawValue,
            playDate: playDate
        ))
        SupabaseSyncQueue.enqueue(.gameRound(
            userID: user.id,
            roundKind: roundKind.rawValue,
            playMode: playMode?.rawValue,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            roundPoints: points
        ))
        if roundKind == .dailyJackpot {
            SupabaseSyncQueue.enqueue(.dailyCompletion(
                userID: user.id,
                playDate: playDate,
                pointsEarned: points
            ))
        }
        Task { await flushPending() }
    }

    static func submitReport(catalogID: String, reason: QuestionReportReason, userID: String?) {
        guard SupabaseConfig.isConfigured else { return }
        SupabaseSyncQueue.enqueue(.questionReport(
            catalogID: catalogID,
            reason: reason.rawValue,
            userID: userID
        ))
        Task { await flushPending() }
    }

    static func syncStatsSnapshot() {
        guard SupabaseConfig.isConfigured else { return }
        let playDate = DailyGameService.dayKey()
        for (catalogID, stats) in QuestionStatsStore.allStats() where stats.timesShown > 0 {
            SupabaseSyncQueue.enqueue(.questionStats(
                catalogID: catalogID,
                playDate: playDate,
                timesShown: stats.timesShown,
                timesCorrect: stats.timesCorrect,
                timesIncorrect: stats.timesIncorrect,
                timesTimedOut: stats.timesTimedOut,
                reportCount: stats.reportCount
            ))
        }
    }

    static func flushPending(accessToken: String? = nil) async {
        guard let client = SupabaseHTTPClient() else { return }
        let token = accessToken ?? SupabaseSessionStore.current?.accessToken
        guard token != nil else { return }

        var remaining = SupabaseSyncQueue.all()
        var index = 0
        while index < remaining.count {
            let op = remaining[index]
            do {
                try await perform(op, client: client, accessToken: token!)
                index += 1
            } catch {
                remaining = Array(remaining[index...])
                SupabaseSyncQueue.replaceAll(remaining)
                return
            }
        }
        SupabaseSyncQueue.replaceAll([])
    }

  // MARK: - Operations

    private static func perform(
        _ op: SupabaseSyncOperation,
        client: SupabaseHTTPClient,
        accessToken: String
    ) async throws {
        switch op {
        case .leaderboard(let userID, let displayName, let points, let correct, let total, let kind, let playDate):
            let row = LeaderboardInsert(
                userID: userID,
                displayName: displayName,
                points: points,
                correctAnswers: correct,
                totalQuestions: total,
                roundKind: kind,
                playDate: playDate
            )
            _ = try await client.post(
                path: "/rest/v1/leaderboard_scores",
                body: [row],
                accessToken: accessToken
            )

        case .gameRound(let userID, let kind, let playMode, let total, let correct, let points):
            let row = GameRoundInsert(
                userID: userID,
                roundKind: kind,
                playMode: playMode,
                totalQuestions: total,
                correctAnswers: correct,
                roundPoints: points,
                completedAt: ISO8601DateFormatter().string(from: .now)
            )
            _ = try await client.post(
                path: "/rest/v1/game_rounds",
                body: [row],
                accessToken: accessToken
            )

        case .dailyCompletion(let userID, let playDate, let points):
            let row = DailyCompletionInsert(
                userID: userID,
                playDate: playDate,
                pointsEarned: points
            )
            _ = try await client.post(
                path: "/rest/v1/daily_completions",
                body: [row],
                accessToken: accessToken,
                prefer: "resolution=merge-duplicates"
            )

        case .questionReport(let catalogID, let reason, let userID):
            let row = QuestionReportInsert(
                catalogSlug: catalogID,
                userID: userID,
                reason: reason
            )
            _ = try await client.post(
                path: "/rest/v1/question_reports",
                body: [row],
                accessToken: accessToken
            )

        case .questionStats(let catalogID, let playDate, let shown, let correct, let incorrect, let timedOut, let reports):
            let body = StatsRPCBody(
                catalogSlug: catalogID,
                playDate: playDate,
                timesShown: shown,
                timesCorrect: correct,
                timesIncorrect: incorrect,
                timesTimedOut: timedOut,
                reportCount: reports
            )
            _ = try await client.rpc(name: "upsert_question_stats_by_slug", body: body, accessToken: accessToken)
        }
    }

    private struct LeaderboardInsert: Encodable {
        let userID: String
        let displayName: String
        let points: Int
        let correctAnswers: Int
        let totalQuestions: Int
        let roundKind: String
        let playDate: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case displayName = "display_name"
            case points
            case correctAnswers = "correct_answers"
            case totalQuestions = "total_questions"
            case roundKind = "round_kind"
            case playDate = "play_date"
        }
    }

    private struct GameRoundInsert: Encodable {
        let userID: String
        let roundKind: String
        let playMode: String?
        let totalQuestions: Int
        let correctAnswers: Int
        let roundPoints: Int
        let completedAt: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case roundKind = "round_kind"
            case playMode = "play_mode"
            case totalQuestions = "total_questions"
            case correctAnswers = "correct_answers"
            case roundPoints = "round_points"
            case completedAt = "completed_at"
        }
    }

    private struct DailyCompletionInsert: Encodable {
        let userID: String
        let playDate: String
        let pointsEarned: Int

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case playDate = "play_date"
            case pointsEarned = "points_earned"
        }
    }

    private struct QuestionReportInsert: Encodable {
        let catalogSlug: String
        let userID: String?
        let reason: String

        enum CodingKeys: String, CodingKey {
            case catalogSlug = "catalog_slug"
            case userID = "user_id"
            case reason
        }
    }

    private struct StatsRPCBody: Encodable {
        let catalogSlug: String
        let playDate: String
        let timesShown: Int
        let timesCorrect: Int
        let timesIncorrect: Int
        let timesTimedOut: Int
        let reportCount: Int

        enum CodingKeys: String, CodingKey {
            case catalogSlug = "p_catalog_slug"
            case playDate = "p_play_date"
            case timesShown = "p_times_shown"
            case timesCorrect = "p_times_correct"
            case timesIncorrect = "p_times_incorrect"
            case timesTimedOut = "p_times_timed_out"
            case reportCount = "p_report_count"
        }
    }
}
