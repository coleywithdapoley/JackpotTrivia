//
//  QuestionCatalogLoader.swift
//  JackpotTrivia
//
//  Bundled JSON question bank (CMS-ready). Falls back to inline samples in QuestionBank.
//

import Foundation

enum QuestionCatalogLoader {
    static let bundledFileName = "QuestionCatalog"

    static func loadRawFromBundle() -> QuestionCatalogFile? {
        guard let url = Bundle.main.url(forResource: bundledFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(QuestionCatalogFile.self, from: data) else {
            return nil
        }
        return catalog
    }

    static func loadFromBundle() -> [TriviaQuestion] {
        guard let catalog = loadRawFromBundle() else { return [] }
        return catalog.questions.compactMap { $0.toTriviaQuestion() }
    }

    /// Bundled JSON plus device-local questions from admin entry.
    static func loadMergedQuestions() -> [TriviaQuestion] {
        let bundle = loadFromBundle()
        let custom = QuestionCatalogStore.customQuestions()
        return bundle + custom
    }

    static var catalogStats: (count: Int, categories: Int, version: Int, approved: Int) {
        guard let catalog = loadRawFromBundle() else {
            return (0, 0, 0, 0)
        }
        let categories = Set(catalog.questions.map(\.category)).count
        let approved = catalog.questions.filter {
            ($0.status ?? "approved") == QuestionStatus.approved.rawValue
        }.count
        return (catalog.questions.count, categories, catalog.version, approved)
    }
}
