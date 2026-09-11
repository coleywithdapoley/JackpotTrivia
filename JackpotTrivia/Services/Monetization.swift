//
//  Monetization.swift
//  JackpotTrivia
//
//  Internal access tier and feature gates. No StoreKit yet.
//  TODO: Replace hard-coded tier with StoreKit 2 product entitlement checks.
//

import Foundation
import SwiftUI

// MARK: - Access tier

enum AccessTier: String, Equatable {
    case free
    case premium
}

// MARK: - Feature gates

struct FeatureGates: Equatable {
    let tier: AccessTier

    init(tier: AccessTier) {
        self.tier = tier
    }

    /// Builds gates from AppConfig until StoreKit supplies the live tier.
    static var current: FeatureGates {
        if PremiumAccessStore.isMockUnlocked {
            return FeatureGates(tier: .premium)
        }
        return FeatureGates(tier: AppConfig.defaultAccessTier)
    }

    var maxQuestionsPerGame: Int {
        switch tier {
        case .free: return AppConfig.dailyQuestionCount
        case .premium: return 20
        }
    }

    var maxCategoriesSelectable: Int {
        switch tier {
        case .free: return 2
        case .premium: return Int.max
        }
    }

    var showsAds: Bool {
        switch tier {
        case .free: return true
        case .premium: return false
        }
    }

    var isFreeTier: Bool { tier == .free }

    var tierDisplayName: String {
        switch tier {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }

    /// Human-readable limits for admin / debug surfaces.
    var limitsSummary: String {
        switch tier {
        case .free:
            return "Up to \(maxQuestionsPerGame) questions per game, \(maxCategoriesSelectable) categories per round."
        case .premium:
            return "Up to \(maxQuestionsPerGame) questions per game, unlimited categories."
        }
    }

    func cappedQuestions(_ questions: [TriviaQuestion]) -> [TriviaQuestion] {
        Array(questions.prefix(maxQuestionsPerGame))
    }

    func canSelectAdditionalCategories(currentCount: Int) -> Bool {
        currentCount < maxCategoriesSelectable
    }

    /// Applies the per-game question cap to an active session.
    func applyQuestionLimit(to session: GameSession) {
        let capped = cappedQuestions(session.currentRoundQuestions)
        guard capped.count != session.currentRoundQuestions.count else { return }
        session.startRound(
            with: capped,
            categories: session.selectedCategories
        )
        if session.currentQuestionIndex >= session.totalQuestions {
            session.currentQuestionIndex = max(0, session.totalQuestions - 1)
        }
    }
}

// MARK: - SwiftUI environment

private struct FeatureGatesKey: EnvironmentKey {
    static let defaultValue = FeatureGates(tier: .free)
}

extension EnvironmentValues {
    var featureGates: FeatureGates {
        get { self[FeatureGatesKey.self] }
        set { self[FeatureGatesKey.self] = newValue }
    }
}

// MARK: - Mock premium (demo until StoreKit)

enum PremiumAccessStore {
    private static let mockUnlockedKey = "jackpotTrivia.mockPremiumUnlocked"

    static var isMockUnlocked: Bool {
        get { UserDefaults.standard.bool(forKey: mockUnlockedKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: mockUnlockedKey)
            NotificationCenter.default.post(name: .premiumAccessDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let premiumAccessDidChange = Notification.Name("premiumAccessDidChange")
}
