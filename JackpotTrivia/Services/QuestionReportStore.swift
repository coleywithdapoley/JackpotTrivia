//
//  QuestionReportStore.swift
//  JackpotTrivia
//

import Foundation

enum QuestionReportStore {
    private static let key = "jackpotTrivia.questions.reports"

    static func submit(
        catalogID: String,
        reason: QuestionReportReason,
        userID: String? = nil
    ) {
        var reports = loadAll()
        reports.append(QuestionReport(
            catalogID: catalogID,
            reason: reason,
            userID: userID
        ))
        saveAll(reports)
        QuestionStatsStore.incrementReportCount(catalogID: catalogID)
        SupabaseSyncService.submitReport(catalogID: catalogID, reason: reason, userID: userID)
    }

    static func allReports() -> [QuestionReport] {
        loadAll().sorted { $0.reportedAt > $1.reportedAt }
    }

    static func unreviewedReports() -> [QuestionReport] {
        allReports().filter { !$0.reviewed }
    }

    static func unreviewedCatalogIDs() -> [String] {
        Array(Set(unreviewedReports().map(\.catalogID)))
    }

    static func markReviewed(catalogID: String) {
        var reports = loadAll()
        for index in reports.indices where reports[index].catalogID == catalogID {
            reports[index].reviewed = true
        }
        saveAll(reports)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func loadAll() -> [QuestionReport] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([QuestionReport].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func saveAll(_ reports: [QuestionReport]) {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
