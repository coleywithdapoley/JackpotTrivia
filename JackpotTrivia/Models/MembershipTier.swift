//
//  MembershipTier.swift
//  JackpotTrivia
//

import Foundation

/// Lounge / member perks — separate from freemium `AccessTier` in Monetization.swift.
enum MembershipTier: String, Codable, CaseIterable, Equatable {
    case free
    case member

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .member: return "Member"
        }
    }

    var isMember: Bool { self == .member }
}
