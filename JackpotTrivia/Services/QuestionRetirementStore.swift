//
//  QuestionRetirementStore.swift
//  JackpotTrivia
//
//  Locally retires questions until Phase 3 sets is_active in Supabase.
//

import Foundation

enum QuestionRetirementStore {
    private static let key = "jackpotTrivia.questions.retiredIDs"

    static var retiredCatalogIDs: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: key)
        }
    }

    static func retire(catalogID: String) {
        var ids = retiredCatalogIDs
        ids.insert(catalogID)
        retiredCatalogIDs = ids
    }

    static func unretire(catalogID: String) {
        var ids = retiredCatalogIDs
        ids.remove(catalogID)
        retiredCatalogIDs = ids
    }

    static func isRetired(catalogID: String) -> Bool {
        retiredCatalogIDs.contains(catalogID)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
