//
//  RoundKind.swift
//  JackpotTrivia
//

import Foundation

/// Distinguishes the official daily jackpot run from casual practice.
enum RoundKind: String, Codable, Equatable {
    case dailyJackpot
    case practice
    /// Invite-only 18+ deck (mature-flagged questions).
    case privateLounge
    /// First-session warmup — separate from official daily jackpot.
    case onboardingWarmup
}
