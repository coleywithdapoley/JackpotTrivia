//
//  RecentQuestionStore.swift
//  JackpotTrivia
//
//  Tracks recently played questions so practice rounds feel fresher.
//

import Foundation

enum RecentQuestionStore {
    private static let key = "jackpotTrivia.recent.catalogIDs"
    private static let maxStored = 30

    /// Most recently played catalog IDs (newest first).
    static var recentCatalogIDs: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// Prefer questions not seen in recent practice rounds when enough remain in the pool.
    static func deprioritizingRecent(_ pool: [TriviaQuestion]) -> [TriviaQuestion] {
        let recent = Set(recentCatalogIDs)
        guard !recent.isEmpty else { return pool }

        let fresh = pool.filter { !recent.contains($0.catalogID) }
        if fresh.count >= AppConfig.minimumPracticePoolSize {
            return fresh
        }
        return pool
    }

    static func recordRound(catalogIDs: [String]) {
        guard !catalogIDs.isEmpty else { return }
        var recent = recentCatalogIDs
        for id in catalogIDs.reversed() {
            recent.removeAll { $0 == id }
            recent.insert(id, at: 0)
        }
        if recent.count > maxStored {
            recent = Array(recent.prefix(maxStored))
        }
        UserDefaults.standard.set(recent, forKey: key)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
