//
//  PrivateAccessStore.swift
//  JackpotTrivia
//
//  Separate gate for the invite-only private lounge (18+ / mature deck).
//

import Foundation

enum PrivateAccessStore {
    private static let unlockedKey = "jackpotTrivia.privateLounge.unlocked"

    static var hasPrivateLoungeAccess: Bool {
        UserDefaults.standard.bool(forKey: unlockedKey)
    }

    static func grantAccess() {
        UserDefaults.standard.set(true, forKey: unlockedKey)
    }

    static func revokeAccess() {
        UserDefaults.standard.removeObject(forKey: unlockedKey)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: unlockedKey)
    }
}
