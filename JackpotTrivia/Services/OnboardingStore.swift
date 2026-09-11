//
//  OnboardingStore.swift
//  JackpotTrivia
//

import Foundation

enum OnboardingStore {
    private static let prefix = "jackpotTrivia.onboarding.warmupCompleted."
    private static let quickHitKey = "jackpotTrivia.onboarding.quickHitCompleted"

    static var hasCompletedQuickHit: Bool {
        UserDefaults.standard.bool(forKey: quickHitKey)
    }

    static func markQuickHitCompleted() {
        UserDefaults.standard.set(true, forKey: quickHitKey)
    }

    static func resetQuickHitForTesting() {
        UserDefaults.standard.removeObject(forKey: quickHitKey)
    }

    static func hasCompletedWarmup(for userID: String) -> Bool {
        UserDefaults.standard.bool(forKey: prefix + userID)
    }

    static func markWarmupCompleted(for userID: String) {
        UserDefaults.standard.set(true, forKey: prefix + userID)
    }

    static func resetWarmup(for userID: String) {
        UserDefaults.standard.removeObject(forKey: prefix + userID)
    }

    static func resetAllForTesting() {
        UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
