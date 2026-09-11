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
    /// Legacy warmup-only round (superseded by first-jackpot segment; kept for tests).
    case onboardingWarmup
    /// Guest Detroit Quick Hit — no login, does not count toward daily jackpot.
    case quickHitSample
}
