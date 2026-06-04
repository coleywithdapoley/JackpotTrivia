//
//  MemberRole.swift
//  JackpotTrivia
//
//  Invite pyramid from product call: founders → tier-2 (2 invites) → tier-3 (no invites).
//

import Foundation

enum MemberRole: String, Codable, CaseIterable {
    /// Tier 1 — founders (you/Kwan); generous invite quota.
    case founder
    /// Tier 2 — invited by a founder; may invite a limited number.
    case member
    /// Tier 3 — invited by tier 2; cannot invite others.
    case leaf

    var displayName: String {
        switch self {
        case .founder: return "Founder"
        case .member: return "Member"
        case .leaf: return "Guest"
        }
    }

    var maxReferrals: Int {
        switch self {
        case .founder: return AppConfig.founderReferralLimit
        case .member: return AppConfig.tier2ReferralLimit
        case .leaf: return 0
        }
    }

    /// Role assigned to someone who redeems this member's invite.
    var roleForInvitee: MemberRole {
        switch self {
        case .founder: return .member
        case .member: return .leaf
        case .leaf: return .leaf
        }
    }
}
