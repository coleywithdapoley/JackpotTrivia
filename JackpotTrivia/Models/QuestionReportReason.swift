//
//  QuestionReportReason.swift
//  JackpotTrivia
//

import Foundation

enum QuestionReportReason: String, CaseIterable, Identifiable, Codable {
    case wrongAnswer
    case unclearWording
    case offensiveContent
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wrongAnswer: return "Wrong answer"
        case .unclearWording: return "Unclear wording"
        case .offensiveContent: return "Offensive content"
        case .other: return "Other"
        }
    }
}

struct QuestionReport: Codable, Equatable, Identifiable {
    let id: String
    let catalogID: String
    let reason: QuestionReportReason
    let reportedAt: Date
    let userID: String?
    var reviewed: Bool

    init(
        id: String = UUID().uuidString,
        catalogID: String,
        reason: QuestionReportReason,
        reportedAt: Date = .now,
        userID: String? = nil,
        reviewed: Bool = false
    ) {
        self.id = id
        self.catalogID = catalogID
        self.reason = reason
        self.reportedAt = reportedAt
        self.userID = userID
        self.reviewed = reviewed
    }
}
