//
//  BackendEnvironment.swift
//  JackpotTrivia
//

import Foundation

enum BackendEnvironment {
    static func makeAuthService() -> AuthServiceProtocol {
        if SupabaseConfig.isConfigured {
            return SupabaseAuthService.shared
        }
        return LocalAuthService.shared
    }

    static func bootstrap() async {
        guard SupabaseConfig.isConfigured else { return }

        let token = SupabaseAuthService.shared.accessToken
        await QuestionRepository.shared.refreshCatalog(accessToken: token)
        await QuestionRepository.shared.refreshDailyDeck(
            playDate: DailyGameService.dayKey(),
            accessToken: token
        )

        if let token {
            await SupabaseSyncService.flushPending(accessToken: token)
            SupabaseSyncService.syncStatsSnapshot()
            await SupabaseSyncService.flushPending(accessToken: token)
        }

        if await fetchRemoteDailyCompletion(accessToken: token) {
            DailyGameService.markDailyCompleted()
        }
    }

    private static func fetchRemoteDailyCompletion(accessToken: String?) async -> Bool {
        guard let client = SupabaseHTTPClient(),
              let token = accessToken,
              let userID = SupabaseSessionStore.current?.userID else {
            return false
        }

        let playDate = DailyGameService.dayKey()
        let query = [
            URLQueryItem(name: "select", value: "play_date"),
            URLQueryItem(name: "user_id", value: "eq.\(userID)"),
            URLQueryItem(name: "play_date", value: "eq.\(playDate)"),
            URLQueryItem(name: "limit", value: "1"),
        ] // PostgREST AND: user_id + play_date

        do {
            let data = try await client.get(
                path: "/rest/v1/daily_completions",
                query: query,
                accessToken: token
            )
            let rows = try JSONDecoder().decode([DailyCompletionRow].self, from: data)
            return !rows.isEmpty
        } catch {
            return false
        }
    }

    private struct DailyCompletionRow: Decodable {
        let playDate: String

        enum CodingKeys: String, CodingKey {
            case playDate = "play_date"
        }
    }
}
