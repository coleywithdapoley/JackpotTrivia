//
//  GamePlayMode.swift
//  JackpotTrivia
//

import Foundation

/// How the player chooses questions for a round (client: two session choices).
enum GamePlayMode: String, CaseIterable, Identifiable, Codable {
    /// Pick one or more categories (optionally narrowed to one).
    case chooseCategories
    /// Party mode — random questions from every category.
    case partyMode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chooseCategories: return "Pick Categories"
        case .partyMode: return "Party Mode"
        }
    }

    var subtitle: String {
        switch self {
        case .chooseCategories:
            return "Choose categories (or use a mood preset)."
        case .partyMode:
            return "Random questions from every category."
        }
    }
}

/// Mood presets map to category sets automatically.
enum TriviaMood: String, CaseIterable, Identifiable, Codable {
    case deepConversations
    case funnyAndWild
    case dateNight
    case familyGameNight
    case learnSomethingNew
    case debateMode
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .deepConversations: return "Deep Conversations"
        case .funnyAndWild: return "Funny & Wild"
        case .dateNight: return "Date Night"
        case .familyGameNight: return "Family Game Night"
        case .learnSomethingNew: return "Learn Something New"
        case .debateMode: return "Debate Mode"
        case .custom: return "Custom"
        }
    }

    var emoji: String {
        switch self {
        case .deepConversations: return "💬"
        case .funnyAndWild: return "🎉"
        case .dateNight: return "💕"
        case .familyGameNight: return "👨‍👩‍👧‍👦"
        case .learnSomethingNew: return "📚"
        case .debateMode: return "⚖️"
        case .custom: return "✨"
        }
    }
}
