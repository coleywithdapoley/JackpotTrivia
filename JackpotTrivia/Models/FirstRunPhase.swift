//
//  FirstRunPhase.swift
//  JackpotTrivia
//
//  Guest-first onboarding: Detroit Quick Hit → results → auth → first jackpot → home.
//

import Foundation

/// Top-level first-run / guest flow state for `RootContentView`.
enum FirstRunPhase: Equatable {
    /// Splash with “Play Free Sample” and sign-in link.
    case quickHitIntro
    /// Guest 3-question Detroit sample (no account).
    case quickHitPlaying
    /// Post-sample score + account CTA.
    case quickHitResults
    /// Email/password sign-in or sign-up after the sample.
    case auth(showSignUp: Bool = false)
    /// Beta gate — only after account creation when `requireAppAccessCode` is on.
    case appAccessGate
    /// First official daily run (warmup segment + today's jackpot).
    case firstJackpotPlaying
    /// Main hub (`DailyJackpotView`).
    case home
}
