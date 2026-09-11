//
//  QuestionRetirementStore.swift
//  JackpotTrivia
//
//  Locally retires questions. When Supabase is connected, admin retire also
//  writes catalog_retired_slugs so every signed-in player hides the same IDs.
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
            || QuestionRepository.shared.retiredCatalogSlugs.contains(catalogID)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
        QuestionRepository.shared.resetRetiredSlugsForTesting()
    }
}
