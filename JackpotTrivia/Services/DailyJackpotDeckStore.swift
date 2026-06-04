//
//  DailyJackpotDeckStore.swift
//  JackpotTrivia
//

import Foundation

enum DailyJackpotDeckStore {
    private static let prefix = "jackpotTrivia.daily.deckIDs."

    static func deckIDs(for dayKey: String) -> [String]? {
        guard let data = UserDefaults.standard.data(forKey: prefix + dayKey),
              let ids = try? JSONDecoder().decode([String].self, from: data),
              !ids.isEmpty else {
            return nil
        }
        return ids
    }

    static func saveDeckIDs(_ ids: [String], for dayKey: String) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: prefix + dayKey)
    }

    static func resetForTesting() {
        UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
