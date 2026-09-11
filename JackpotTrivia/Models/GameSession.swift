//
//  GameSession.swift
//  JackpotTrivia
//

import Combine
import Foundation

/// Session state for the active trivia round. Used from SwiftUI (`@StateObject` / `@EnvironmentObject`), which runs on the main thread.
final class GameSession: ObservableObject {
    @Published var selectedCategories: [String] = []
    @Published var currentRoundQuestions: [TriviaQuestion] = []
    @Published var totalQuestions: Int = 0
    @Published var correctAnswers: Int = 0
    @Published var currentQuestionIndex: Int = 0
    @Published var playMode: GamePlayMode = .chooseCategories
    @Published var activeMood: TriviaMood = .custom
    @Published var roundKind: RoundKind = .practice
    @Published var roundPoints: Int = 0
    @Published var currentStreak: Int = 0
    @Published var lastAnswerPoints: Int = 0
    @Published var roundForfeited: Bool = false
    @Published var forfeitReason: String?

    private var lastContentProfile: UserContentProfile = .default
    private var roundShuffleSeed: UInt64 = UInt64.random(in: 0...UInt64.max)
    private var peakStreak: Int = 0

    /// Start a round using play mode, mood, and comfort profile.
    func beginRound(
        mode: GamePlayMode,
        mood: TriviaMood,
        selectedCategoryNames: [String],
        narrowToSingleCategory: Bool,
        profile: UserContentProfile = UserProfileStore.profile
    ) {
        roundKind = .practice
        lastContentProfile = profile
        playMode = mode
        activeMood = mood
        let categories = Self.resolveCategories(
            mode: mode,
            mood: mood,
            selected: selectedCategoryNames,
            narrowToSingleCategory: narrowToSingleCategory
        )
        bumpRoundShuffleSeed()
        var generator = SeededRandomNumberGenerator(seed: roundShuffleSeed)
        let questions = QuestionBank.questions(
            for: categories,
            profile: profile,
            using: &generator
        )
        startRound(with: questions, categories: categories)
    }

    /// Invite-only mature deck (private lounge).
    func beginPrivateLoungeRound() {
        roundKind = .privateLounge
        playMode = .partyMode
        activeMood = .custom
        roundForfeited = false
        forfeitReason = nil
        bumpRoundShuffleSeed()
        var profile = UserProfileStore.profile
        profile.matureTopicsEnabled = true
        profile.familySafeMode = false
        lastContentProfile = profile
        let questions = QuestionBank.privateLoungeQuestions()
        startRound(with: questions, categories: ["Private Lounge"])
    }

    func forfeitRound(reason: String) {
        roundForfeited = true
        forfeitReason = reason
    }

    /// Official daily jackpot — one deterministic deck per calendar day.
    func beginDailyRound(profile: UserContentProfile = UserProfileStore.profile) {
        roundKind = .dailyJackpot
        playMode = .partyMode
        activeMood = .custom
        roundForfeited = false
        forfeitReason = nil
        lastContentProfile = profile
        let questions = DailyGameService.questionsForDailyJackpot(profile: profile)
        startRound(with: questions, categories: ["Daily Jackpot"])
    }

    /// Guest Detroit Quick Hit — no account; does not touch daily jackpot.
    func beginQuickHitRound(profile: UserContentProfile = .default) {
        roundKind = .quickHitSample
        playMode = .chooseCategories
        activeMood = .custom
        roundForfeited = false
        forfeitReason = nil
        lastContentProfile = profile
        bumpRoundShuffleSeed()
        let questions = QuestionBank.quickHitQuestions(profile: profile)
        startRound(with: questions, categories: ["Detroit"])
    }

    /// Legacy warmup-only round (tests / admin); prefer `beginFirstDailyJackpotRound` for new users.
    func beginWarmupRound(profile: UserContentProfile = UserProfileStore.profile) {
        roundKind = .onboardingWarmup
        playMode = .chooseCategories
        activeMood = .custom
        roundForfeited = false
        forfeitReason = nil
        lastContentProfile = profile
        bumpRoundShuffleSeed()
        let questions = QuestionBank.warmupQuestions(profile: profile)
        let category = AppConfig.defaultCategories.first ?? "Auto City"
        startRound(with: questions, categories: [category])
    }

    /// First signed-in run: warmup segment + today's jackpot — counts as the official daily run.
    func beginFirstDailyJackpotRound(profile: UserContentProfile = UserProfileStore.profile) {
        roundKind = .dailyJackpot
        playMode = .partyMode
        activeMood = .custom
        roundForfeited = false
        forfeitReason = nil
        lastContentProfile = profile
        let questions = QuestionBank.firstDailyJackpotQuestions(profile: profile)
        startRound(with: questions, categories: ["First Detroit Jackpot"])
    }

    /// Legacy entry — category names only (custom mood, pick-categories mode).
    func beginRound(categories: [String]) {
        beginRound(
            mode: .chooseCategories,
            mood: .custom,
            selectedCategoryNames: categories,
            narrowToSingleCategory: false
        )
    }

    func startRound(with questions: [TriviaQuestion], categories: [String]) {
        selectedCategories = categories
        currentRoundQuestions = questions
        totalQuestions = questions.count
        correctAnswers = 0
        currentQuestionIndex = 0
        roundPoints = 0
        currentStreak = 0
        peakStreak = 0
        lastAnswerPoints = 0
    }

    func incrementCorrectAnswers() {
        correctAnswers += 1
    }

    /// Records scoring, streak, and points for one question.
    @discardableResult
    func recordAnswer(
        isCorrect: Bool,
        timeRemaining: Int,
        timeLimit: Int,
        difficulty: QuestionDifficulty
    ) -> ScoringEngine.AnswerScore {
        let streakAfter = isCorrect ? currentStreak + 1 : 0
        let breakdown = ScoringEngine.score(
            isCorrect: isCorrect,
            timeRemaining: timeRemaining,
            timeLimit: timeLimit,
            difficulty: difficulty,
            streakAfterAnswer: streakAfter
        )

        if isCorrect {
            correctAnswers += 1
            currentStreak = streakAfter
            peakStreak = max(peakStreak, currentStreak)
        } else {
            currentStreak = 0
        }

        roundPoints += breakdown.total
        lastAnswerPoints = breakdown.total
        return breakdown
    }

    /// Credits wallet, marks daily complete, and posts to leaderboards.
    func finalizeRound(for user: AuthUser?) {
        if roundKind == .practice || roundKind == .privateLounge {
            RecentQuestionStore.recordRound(catalogIDs: currentRoundQuestions.map(\.catalogID))
        }

        if roundKind == .quickHitSample {
            OnboardingStore.markQuickHitCompleted()
        } else if roundKind == .dailyJackpot {
            DailyGameService.markDailyCompleted()
            PrizeWallet.creditRound(points: roundPoints)
            if let user, !OnboardingStore.hasCompletedWarmup(for: user.id) {
                OnboardingStore.markWarmupCompleted(for: user.id)
            }
        } else if roundKind == .onboardingWarmup, let user {
            OnboardingStore.markWarmupCompleted(for: user.id)
            PrizeWallet.creditRound(points: roundPoints)
        }

        if let user {
            PlayerProgressStore.recordRound(
                for: user.id,
                correctAnswers: correctAnswers,
                streakPeak: peakStreak,
                xpEarned: roundPoints
            )
            PlayerProgressStore.syncXPFromWallet(for: user.id)
        }

        guard let user, roundPoints > 0 || roundKind == .dailyJackpot || roundKind == .onboardingWarmup else { return }
        let name = user.displayName ?? user.email
        if roundKind != .onboardingWarmup, roundKind != .quickHitSample {
            LeaderboardService.recordRound(
                userID: user.id,
                displayName: name,
                points: roundPoints,
                correctAnswers: correctAnswers,
                totalQuestions: totalQuestions,
                roundKind: roundKind
            )
            SupabaseSyncService.recordRound(
                user: user,
                points: roundPoints,
                correctAnswers: correctAnswers,
                totalQuestions: totalQuestions,
                roundKind: roundKind,
                playMode: playMode
            )
        }
    }

    /// Backward-compatible alias used by older call sites.
    func completeRoundIfDaily() {
        finalizeRound(for: nil)
    }

    func resetForReplay() {
        roundForfeited = false
        forfeitReason = nil
        bumpRoundShuffleSeed()
        let questions: [TriviaQuestion]
        switch roundKind {
        case .dailyJackpot:
            questions = DailyGameService.questionsForDailyJackpot(profile: lastContentProfile)
        case .privateLounge:
            questions = QuestionBank.privateLoungeQuestions()
        case .quickHitSample:
            questions = QuestionBank.quickHitQuestions(profile: lastContentProfile)
        case .practice, .onboardingWarmup:
            questions = shuffledPracticeQuestions()
        }
        startRound(with: questions, categories: selectedCategories)
    }

    private func bumpRoundShuffleSeed() {
        roundShuffleSeed = UInt64.random(in: 0...UInt64.max)
    }

    private func shuffledPracticeQuestions() -> [TriviaQuestion] {
        var generator = SeededRandomNumberGenerator(seed: roundShuffleSeed)
        return QuestionBank.questions(
            for: selectedCategories,
            profile: lastContentProfile,
            using: &generator
        )
    }

    func clearRound() {
        selectedCategories = []
        currentRoundQuestions = []
        totalQuestions = 0
        correctAnswers = 0
        currentQuestionIndex = 0
        playMode = .chooseCategories
        activeMood = .custom
        roundKind = .practice
        roundPoints = 0
        currentStreak = 0
        peakStreak = 0
        lastAnswerPoints = 0
        roundForfeited = false
        forfeitReason = nil
    }

    static func resolveCategories(
        mode: GamePlayMode,
        mood: TriviaMood,
        selected: [String],
        narrowToSingleCategory: Bool
    ) -> [String] {
        switch mode {
        case .partyMode:
            return []
        case .chooseCategories:
            let base: [String]
            if mood != .custom {
                base = AppConfig.categories(for: mood)
            } else {
                base = selected
            }
            if narrowToSingleCategory, base.count == 1 {
                return base
            }
            return base
        }
    }
}
