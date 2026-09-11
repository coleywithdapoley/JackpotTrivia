//
//  QuestionBank.swift
//  JackpotTrivia
//

import Foundation

/// Question pool from Supabase when configured, else bundled JSON (`QuestionCatalog.json`).
enum QuestionBank {
    static var allQuestions: [TriviaQuestion] {
        if SupabaseConfig.isConfigured {
            return QuestionRepository.shared.playablePool()
        }
        let catalog = QuestionCatalogLoader.loadMergedQuestions()
        let pool = catalog.isEmpty ? embeddedFallbackQuestions : catalog
        return playableQuestions(from: pool)
    }

    /// Mature-flagged approved questions for the private lounge.
    static func privateLoungeQuestions(count: Int = AppConfig.privateLoungeQuestionCount) -> [TriviaQuestion] {
        var profile = UserProfileStore.profile
        profile.matureTopicsEnabled = true
        profile.familySafeMode = false
        let pool = allQuestions.filter { $0.content.allowsMatureTopics }
        let filtered = filteredQuestions(for: [], profile: profile, from: pool)
        let source = filtered.isEmpty ? pool : filtered
        return Array(source.shuffled().prefix(count))
    }

    /// Used by `QuestionRepository` when the bundle is empty.
    static var bundledFallbackPool: [TriviaQuestion] {
        embeddedFallbackQuestions
    }

    /// Approved, not locally retired, deduped by catalog ID.
    static func playableQuestions(from pool: [TriviaQuestion]) -> [TriviaQuestion] {
        var seen = Set<String>()
        return pool.filter { question in
            guard question.status.isPlayable else { return false }
            guard !QuestionRetirementStore.isRetired(catalogID: question.catalogID) else { return false }
            guard seen.insert(question.catalogID).inserted else { return false }
            return true
        }
    }

    private static let embeddedFallbackQuestions: [TriviaQuestion] = [
        TriviaQuestion(
            catalogID: "detroit-fallback-motown",
            category: "Motown & Music",
            question: "Motown Records was founded in which city?",
            answers: ["Chicago", "Detroit", "Memphis", "Atlanta"],
            correctIndex: 1
        ),
        TriviaQuestion(
            catalogID: "detroit-fallback-auto",
            category: "Auto City",
            question: "Detroit is known as the Motor City.",
            answers: QuestionType.trueFalseAnswers,
            correctIndex: 0,
            questionType: .trueFalse,
            difficulty: .easy
        ),
    ]

    static func matchesContent(_ question: TriviaQuestion, profile: UserContentProfile) -> Bool {
        let prefs = profile.resolvedForFiltering()
        if prefs.familySafeMode, !question.content.isFamilySafe { return false }
        if !prefs.matureTopicsEnabled, question.content.allowsMatureTopics { return false }
        if prefs.educationalOnly, !question.content.isEducational { return false }
        return true
    }

    static func filteredQuestions(
        for categories: [String],
        profile: UserContentProfile = .default,
        from pool: [TriviaQuestion] = allQuestions
    ) -> [TriviaQuestion] {
        let categoryFiltered: [TriviaQuestion]
        if categories.isEmpty {
            categoryFiltered = pool
        } else {
            let filtered = pool.filter { categories.contains($0.category) }
            categoryFiltered = filtered.isEmpty ? pool : filtered
        }
        let contentFiltered = categoryFiltered.filter { matchesContent($0, profile: profile) }
        return contentFiltered.isEmpty ? categoryFiltered : contentFiltered
    }

    static func questions(
        for categories: [String],
        profile: UserContentProfile = .default,
        excludingJackpotIDs: Set<String> = DailyGameService.todaysJackpotQuestionIDs(),
        from pool: [TriviaQuestion] = allQuestions
    ) -> [TriviaQuestion] {
        var filtered = filteredQuestions(for: categories, profile: profile, from: pool)
            .filter(\.isPracticeEligible)
            .filter { !excludingJackpotIDs.contains($0.catalogID) }

        filtered = RecentQuestionStore.deprioritizingRecent(filtered)

        if filtered.count < AppConfig.minimumPracticePoolSize {
            #if DEBUG
            print("[QuestionBank] Practice pool small after excluding today's jackpot (\(filtered.count)); allowing overlap.")
            #endif
            filtered = filteredQuestions(for: categories, profile: profile, from: pool)
                .filter(\.isPracticeEligible)
        }

        return filtered.shuffled()
    }

    static func questions(
        for categories: [String],
        profile: UserContentProfile,
        using generator: inout some RandomNumberGenerator
    ) -> [TriviaQuestion] {
        let base = filteredQuestions(for: categories, profile: profile)
            .filter(\.isPracticeEligible)
            .filter { !DailyGameService.todaysJackpotQuestionIDs().contains($0.catalogID) }
        let recencyAware = RecentQuestionStore.deprioritizingRecent(base)
        let source = recencyAware.count >= AppConfig.minimumPracticePoolSize
            ? recencyAware
            : (base.count >= AppConfig.minimumPracticePoolSize
                ? base
                : filteredQuestions(for: categories, profile: profile).filter(\.isPracticeEligible))
        return source.shuffled(using: &generator)
    }

    static func warmupQuestions(
        count: Int = AppConfig.onboardingWarmupQuestionCount,
        profile: UserContentProfile = UserProfileStore.profile
    ) -> [TriviaQuestion] {
        let categories = [AppConfig.defaultCategories.first ?? "Downtown & Neighborhoods"]
        var generator = SeededRandomNumberGenerator(seed: UInt64(Date().timeIntervalSince1970))
        let pool = questions(for: categories, profile: profile, using: &generator)
        return Array(pool.prefix(count))
    }

    /// Curated Motor City sample for guest Quick Hit (falls back to Sports / History / Music).
    static func quickHitQuestions(
        count: Int = AppConfig.quickHitQuestionCount,
        profile: UserContentProfile = .default
    ) -> [TriviaQuestion] {
        var generator = SeededRandomNumberGenerator(seed: 0xDE770117)
        let curated = detroitQuickHitPool.filter { matchesContent($0, profile: profile) }
        if curated.count >= count {
            return Array(curated.shuffled(using: &generator).prefix(count))
        }

        let detroitCategories = Array(AppConfig.detroitThemedCategories)
        var themed = filteredQuestions(for: detroitCategories, profile: profile)
            .filter(\.isPracticeEligible)
        if themed.count < count {
            themed = filteredQuestions(for: [], profile: profile).filter(\.isPracticeEligible)
        }
        let merged = (curated + themed).uniqued(by: \.catalogID)
        return Array(merged.shuffled(using: &generator).prefix(count))
    }

    /// First signed-in daily run: warmup segment + today's official jackpot deck (deduped).
    static func firstDailyJackpotQuestions(
        profile: UserContentProfile = UserProfileStore.profile,
        warmupCount: Int = AppConfig.onboardingWarmupQuestionCount,
        dailyCount: Int = AppConfig.dailyQuestionCount,
        date: Date = .now
    ) -> [TriviaQuestion] {
        let warmup = warmupQuestions(count: warmupCount, profile: profile)
        let warmupIDs = Set(warmup.map(\.catalogID))
        let daily = DailyGameService.questionsForDailyJackpot(
            profile: profile,
            count: dailyCount,
            date: date
        ).filter { !warmupIDs.contains($0.catalogID) }
        return warmup + daily
    }

    private static let detroitQuickHitPool: [TriviaQuestion] = [
        TriviaQuestion(
            catalogID: "detroit-quickhit-motown",
            category: "Motown & Music",
            question: "Motown Records was founded in which city?",
            answers: ["Chicago", "Detroit", "Memphis", "Atlanta"],
            correctIndex: 1,
            difficulty: .easy
        ),
        TriviaQuestion(
            catalogID: "detroit-quickhit-lions",
            category: "Detroit Sports",
            question: "Which NFL team plays home games in Detroit?",
            answers: ["Bears", "Packers", "Lions", "Browns"],
            correctIndex: 2,
            difficulty: .easy
        ),
        TriviaQuestion(
            catalogID: "detroit-quickhit-automotive",
            category: "Auto City",
            question: "Detroit is widely known as the historic center of which U.S. industry?",
            answers: ["Steel", "Automobiles", "Textiles", "Shipbuilding"],
            correctIndex: 1,
            difficulty: .easy
        ),
        TriviaQuestion(
            catalogID: "detroit-quickhit-river",
            category: "Downtown & Neighborhoods",
            question: "Detroit sits on the bank of which river?",
            answers: ["Mississippi", "Hudson", "Detroit River", "Ohio River"],
            correctIndex: 2,
            difficulty: .easy
        ),
    ]

    static func presentedQuestion(from question: TriviaQuestion) -> PresentedQuestion {
        var pairs = question.answers.enumerated().map { ($0, $1) }
        pairs.shuffle()

        let shuffledAnswers = pairs.map(\.1)
        let correctIndex = pairs.firstIndex { $0.0 == question.correctIndex } ?? question.correctIndex

        return PresentedQuestion(
            catalogID: question.catalogID,
            category: question.category,
            question: question.question,
            answers: shuffledAnswers,
            correctIndex: correctIndex,
            questionType: question.questionType,
            difficulty: question.difficulty,
            timeLimitSeconds: question.effectiveTimeLimitSeconds
        )
    }
}

private extension Array {
    func uniqued<ID: Hashable>(by keyPath: KeyPath<Element, ID>) -> [Element] {
        var seen = Set<ID>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
