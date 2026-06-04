//
//  QuestionContentFlags.swift
//  JackpotTrivia
//

import Foundation

struct QuestionContentFlags: Equatable, Codable {
    var allowsMatureTopics: Bool
    var isEducational: Bool
    var isFamilySafe: Bool

    static let standard = QuestionContentFlags(
        allowsMatureTopics: false,
        isEducational: true,
        isFamilySafe: true
    )

    static let mature = QuestionContentFlags(
        allowsMatureTopics: true,
        isEducational: false,
        isFamilySafe: false
    )
}

enum ProfileAgeBand: String, CaseIterable, Identifiable, Codable {
    case family
    case teen
    case adult
    case mixedGroup

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .family: return "Family"
        case .teen: return "Teen"
        case .adult: return "Adult"
        case .mixedGroup: return "Mixed group"
        }
    }
}

/// Comfort / content filters stored per device until account profiles exist.
struct UserContentProfile: Equatable, Codable {
    var matureTopicsEnabled: Bool = false
    var familySafeMode: Bool = true
    var educationalOnly: Bool = false
    var ageBand: ProfileAgeBand = .adult

    static let `default` = UserContentProfile()

    /// Applies age band overrides for mixed or family contexts.
    func resolvedForFiltering() -> UserContentProfile {
        var copy = self
        switch ageBand {
        case .family, .mixedGroup:
            copy.matureTopicsEnabled = false
            copy.familySafeMode = true
        case .teen:
            if copy.matureTopicsEnabled == false {
                copy.familySafeMode = true
            }
        case .adult:
            break
        }
        return copy
    }
}
