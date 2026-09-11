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

    /// Hidden for every signed-in player (admin retire).
    private(set) var retiredCatalogSlugs: Set<String> = []

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
            retiredCatalogSlugs = try await fetchRetiredSlugs(client: client, accessToken: accessToken)
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

    // MARK: - Admin catalog (every player)

    func publishQuestion(
        _ item: QuestionCatalogItem,
        accessToken: String
    ) async throws {
        guard let client else { throw SupabaseHTTPError.notConfigured }
        guard let slug = item.id?.trimmingCharacters(in: .whitespacesAndNewlines), !slug.isEmpty else {
            throw AuthError.message("Question ID is missing.")
        }

        let categoryID = try await categoryID(named: item.category, client: client, accessToken: accessToken)
        let insert = QuestionInsert(
            categoryID: categoryID,
            catalogSlug: slug,
            questionText: item.question,
            questionType: item.questionType ?? QuestionType.multipleChoice.rawValue,
            difficulty: item.difficulty ?? QuestionDifficulty.medium.rawValue,
            timeLimitSeconds: item.timeLimitSeconds,
            correctAnswerIndex: item.correctIndex,
            allowsMatureTopics: item.allowsMatureTopics ?? false,
            isEducational: item.isEducational ?? true,
            isFamilySafe: item.isFamilySafe ?? true,
            status: QuestionStatus.approved.rawValue,
            isActive: true,
            source: "admin-app",
            verifiedAt: ISO8601DateFormatter().string(from: .now)
        )

        let data = try await client.post(
            path: "/rest/v1/questions",
            body: [insert],
            accessToken: accessToken,
            prefer: "return=representation"
        )
        struct IDRow: Decodable { let id: String }
        guard let questionID = try JSONDecoder().decode([IDRow].self, from: data).first?.id else {
            throw SupabaseHTTPError.decodingFailed
        }

        let answers = item.answers.enumerated().map { index, text in
            AnswerInsert(questionID: questionID, sortIndex: index, answerText: text)
        }
        _ = try await client.post(
            path: "/rest/v1/question_answers",
            body: answers,
            accessToken: accessToken
        )

        await refreshCatalog(accessToken: accessToken)
    }

    func retireQuestion(catalogID: String, accessToken: String) async throws {
        guard let client else { throw SupabaseHTTPError.notConfigured }
        let slug = catalogID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slug.isEmpty else { return }

        let row = RetiredSlugInsert(catalogSlug: slug)
        do {
            _ = try await client.post(
                path: "/rest/v1/catalog_retired_slugs",
                body: [row],
                accessToken: accessToken
            )
        } catch {
            if !isUniqueViolation(error) { throw error }
        }

        _ = try? await client.patch(
            path: "/rest/v1/questions",
            query: [URLQueryItem(name: "catalog_slug", value: "eq.\(slug)")],
            body: QuestionActiveUpdate(isActive: false),
            accessToken: accessToken
        )

        retiredCatalogSlugs.insert(slug)
        QuestionRetirementStore.retire(catalogID: slug)
        await refreshCatalog(accessToken: accessToken)
    }

    func restoreQuestion(catalogID: String, accessToken: String) async throws {
        guard let client else { throw SupabaseHTTPError.notConfigured }
        let slug = catalogID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slug.isEmpty else { return }

        _ = try await client.delete(
            path: "/rest/v1/catalog_retired_slugs",
            query: [URLQueryItem(name: "catalog_slug", value: "eq.\(slug)")],
            accessToken: accessToken
        )
        _ = try? await client.patch(
            path: "/rest/v1/questions",
            query: [URLQueryItem(name: "catalog_slug", value: "eq.\(slug)")],
            body: QuestionActiveUpdate(isActive: true),
            accessToken: accessToken
        )

        retiredCatalogSlugs.remove(slug)
        QuestionRetirementStore.unretire(catalogID: slug)
        await refreshCatalog(accessToken: accessToken)
    }

    func resetRetiredSlugsForTesting() {
        retiredCatalogSlugs = []
    }

    private func fetchRetiredSlugs(client: SupabaseHTTPClient, accessToken: String?) async throws -> Set<String> {
        struct Row: Decodable {
            let catalogSlug: String
            enum CodingKeys: String, CodingKey { case catalogSlug = "catalog_slug" }
        }
        let data = try await client.get(
            path: "/rest/v1/catalog_retired_slugs",
            query: [URLQueryItem(name: "select", value: "catalog_slug")],
            accessToken: accessToken
        )
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return Set(rows.map(\.catalogSlug))
    }

    private func categoryID(
        named name: String,
        client: SupabaseHTTPClient,
        accessToken: String
    ) async throws -> String {
        struct CategoryRow: Decodable { let id: String }
        let data = try await client.get(
            path: "/rest/v1/categories",
            query: [
                URLQueryItem(name: "select", value: "id"),
                URLQueryItem(name: "name", value: "eq.\(name)"),
                URLQueryItem(name: "limit", value: "1"),
            ],
            accessToken: accessToken
        )
        if let id = try JSONDecoder().decode([CategoryRow].self, from: data).first?.id {
            return id
        }

        struct CategoryInsert: Encodable {
            let name: String
            let isActive: Bool
            enum CodingKeys: String, CodingKey {
                case name
                case isActive = "is_active"
            }
        }
        let inserted = try await client.post(
            path: "/rest/v1/categories",
            body: [CategoryInsert(name: name, isActive: true)],
            accessToken: accessToken,
            prefer: "return=representation"
        )
        guard let id = try JSONDecoder().decode([CategoryRow].self, from: inserted).first?.id else {
            throw AuthError.message("Could not create category \(name).")
        }
        return id
    }

    private func isUniqueViolation(_ error: Error) -> Bool {
        let text = error.localizedDescription.lowercased()
        return text.contains("23505") || text.contains("duplicate") || text.contains("unique")
    }

    private struct QuestionInsert: Encodable {
        let categoryID: String
        let catalogSlug: String
        let questionText: String
        let questionType: String
        let difficulty: String
        let timeLimitSeconds: Int?
        let correctAnswerIndex: Int
        let allowsMatureTopics: Bool
        let isEducational: Bool
        let isFamilySafe: Bool
        let status: String
        let isActive: Bool
        let source: String
        let verifiedAt: String

        enum CodingKeys: String, CodingKey {
            case categoryID = "category_id"
            case catalogSlug = "catalog_slug"
            case questionText = "question_text"
            case questionType = "question_type"
            case difficulty
            case timeLimitSeconds = "time_limit_seconds"
            case correctAnswerIndex = "correct_answer_index"
            case allowsMatureTopics = "allows_mature_topics"
            case isEducational = "is_educational"
            case isFamilySafe = "is_family_safe"
            case status
            case isActive = "is_active"
            case source
            case verifiedAt = "verified_at"
        }
    }

    private struct AnswerInsert: Encodable {
        let questionID: String
        let sortIndex: Int
        let answerText: String

        enum CodingKeys: String, CodingKey {
            case questionID = "question_id"
            case sortIndex = "sort_index"
            case answerText = "answer_text"
        }
    }

    private struct RetiredSlugInsert: Encodable {
        let catalogSlug: String

        enum CodingKeys: String, CodingKey {
            case catalogSlug = "catalog_slug"
        }
    }

    private struct QuestionActiveUpdate: Encodable {
        let isActive: Bool
        enum CodingKeys: String, CodingKey { case isActive = "is_active" }
    }
}
