//
//  QuestionRepository.swift
//  JackpotTrivia
//
//  Remote question catalog with bundled fallback.
//

import Foundation

enum QuestionPoolSource: String, Equatable {
    case bundled
    case remote
    case merged
}

final class QuestionRepository {
    static let shared = QuestionRepository()

    private(set) var remoteQuestions: [TriviaQuestion] = []
    private(set) var poolSource: QuestionPoolSource = .bundled
    private(set) var lastRefreshError: String?
    private(set) var remoteDailyQuestions: [TriviaQuestion]?

    /// catalog_slug → Supabase question UUID
    private(set) var remoteIDByCatalogSlug: [String: String] = [:]

    private let client: SupabaseHTTPClient?

    private init() {
        client = SupabaseHTTPClient()
    }

    var isRemoteEnabled: Bool {
        client != nil
    }

    /// Playable pool: remote when available, else bundle.
    func playablePool() -> [TriviaQuestion] {
        let bundle = QuestionCatalogLoader.loadFromBundle()
        let bundlePool = bundle.isEmpty ? QuestionBank.bundledFallbackPool : bundle
        let bundlePlayable = QuestionBank.playableQuestions(from: bundlePool)

        guard !remoteQuestions.isEmpty else {
            poolSource = .bundled
            return bundlePlayable
        }

        let remotePlayable = QuestionBank.playableQuestions(from: remoteQuestions)
        if remotePlayable.isEmpty {
            poolSource = .bundled
            return bundlePlayable
        }

        poolSource = bundlePlayable.isEmpty ? .remote : .merged
        var seen = Set<String>()
        var merged: [TriviaQuestion] = []
        for question in remotePlayable + bundlePlayable where seen.insert(question.catalogID).inserted {
            merged.append(question)
        }
        return merged
    }

    func refreshCatalog(accessToken: String?) async {
        guard let client else { return }
        lastRefreshError = nil

        let select = """
        id,catalog_slug,question_text,question_type,difficulty,time_limit_seconds,\
        correct_answer_index,allows_mature_topics,is_educational,is_family_safe,\
        status,source,verified_at,categories(name),question_answers(sort_index,answer_text)
        """
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: select),
            URLQueryItem(name: "status", value: "eq.approved"),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "order", value: "catalog_slug.asc.nullslast"),
        ]

        do {
            let data = try await client.get(
                path: "/rest/v1/questions",
                query: query,
                accessToken: accessToken
            )
            let rows = try JSONDecoder().decode([SupabaseQuestionRow].self, from: data)
            var idMap: [String: String] = [:]
            let mapped = rows.compactMap { row -> TriviaQuestion? in
                guard let question = row.toTriviaQuestion() else { return nil }
                idMap[question.catalogID] = row.id
                return question
            }
            remoteQuestions = mapped
            remoteIDByCatalogSlug = idMap
        } catch {
            lastRefreshError = error.localizedDescription
        }
    }

    func refreshDailyDeck(playDate: String, accessToken: String?) async {
        guard let client else { return }

        let select = """
        id,play_date,daily_game_questions(sequence_index,questions(\
        id,catalog_slug,question_text,question_type,difficulty,time_limit_seconds,\
        correct_answer_index,allows_mature_topics,is_educational,is_family_safe,\
        status,source,verified_at,categories(name),question_answers(sort_index,answer_text)\
        ))
        """
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: select),
            URLQueryItem(name: "play_date", value: "eq.\(playDate)"),
            URLQueryItem(name: "limit", value: "1"),
        ]

        do {
            let data = try await client.get(
                path: "/rest/v1/daily_games",
                query: query,
                accessToken: accessToken
            )
            let rows = try JSONDecoder().decode([SupabaseDailyGameRow].self, from: data)
            guard let game = rows.first,
                  let items = game.dailyGameQuestions else {
                remoteDailyQuestions = nil
                return
            }
            let ordered = items
                .sorted { $0.sequenceIndex < $1.sequenceIndex }
                .compactMap { $0.questions?.toTriviaQuestion() }
            remoteDailyQuestions = ordered.isEmpty ? nil : QuestionBank.playableQuestions(from: ordered)
        } catch {
            remoteDailyQuestions = nil
        }
    }

    func dailyQuestionsForToday(
        profile: UserContentProfile = UserProfileStore.profile,
        count: Int = AppConfig.dailyQuestionCount
    ) -> [TriviaQuestion]? {
        guard let deck = remoteDailyQuestions, !deck.isEmpty else { return nil }
        let filtered = QuestionBank.filteredQuestions(for: [], profile: profile, from: deck)
        let source = filtered.isEmpty ? deck : filtered
        return Array(source.prefix(count))
    }
}
