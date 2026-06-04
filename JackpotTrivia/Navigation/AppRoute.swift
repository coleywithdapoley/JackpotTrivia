//
//  AppRoute.swift
//  JackpotTrivia
//

import Foundation

/// Main user-flow destinations pushed onto the root `NavigationStack`.
enum AppRoute: Hashable {
    case categorySelection
    case trivia
    case results
    case comfortPreferences
    case leaderboard
    case privateLounge
    case membership
    case addQuestion
}
