//
//  QuestionCatalogStore.swift
//  JackpotTrivia
//
//  Locally added questions (you/Kwan) merged with bundled QuestionCatalog.json.
//

import Foundation

enum QuestionCatalogStore {
    private static let key = "jackpotTrivia.questions.custom"

    static func customQuestions() -> [TriviaQuestion] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([QuestionCatalogItem].self, from: data) else {
            return []
        }
        return items.compactMap { $0.toTriviaQuestion() }
    }

    @discardableResult
    static func append(_ item: QuestionCatalogItem) -> TriviaQuestion? {
        var items = loadItems()
        items.append(item)
        saveItems(items)
        return item.toTriviaQuestion()
    }

    static func remove(catalogID: String) {
        var items = loadItems()
        items.removeAll { ($0.id ?? "") == catalogID }
        saveItems(items)
    }

    static func count() -> Int {
        loadItems().count
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func loadItems() -> [QuestionCatalogItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([QuestionCatalogItem].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func saveItems(_ items: [QuestionCatalogItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
