//
//  QuestionStatus.swift
//  JackpotTrivia
//

import Foundation

enum QuestionStatus: String, Codable, CaseIterable {
    case draft
    case approved
    case retired

    var isPlayable: Bool {
        self == .approved
    }
}
