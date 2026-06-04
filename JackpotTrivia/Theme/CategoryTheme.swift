//
//  CategoryTheme.swift
//  JackpotTrivia
//
//  Lightweight category “wallpaper” tints for trivia (per product call).
//

import SwiftUI

enum CategoryTheme {
    static func backgroundGradient(for category: String) -> LinearGradient {
        let colors = palette(for: category)
        return LinearGradient(
            colors: [colors.0.opacity(0.35), colors.1.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func accentColor(for category: String) -> Color {
        palette(for: category).0
    }

    private static func palette(for category: String) -> (Color, Color) {
        switch category {
        case "Science":
            return (Color(red: 0.2, green: 0.45, blue: 0.85), .white)
        case "History":
            return (Color(red: 0.55, green: 0.38, blue: 0.22), .white)
        case "Sports":
            return (Color(red: 0.15, green: 0.55, blue: 0.35), .white)
        case "Movies & TV":
            return (Color(red: 0.45, green: 0.2, blue: 0.55), .white)
        case "Music":
            return (Color(red: 0.75, green: 0.25, blue: 0.45), .white)
        case "Private Lounge":
            return (Color(red: 0.35, green: 0.1, blue: 0.35), .white)
        default:
            return (AppColors.brandGreen, .white)
        }
    }
}
