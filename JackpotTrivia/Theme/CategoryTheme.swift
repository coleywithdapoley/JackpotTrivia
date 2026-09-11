//
//  CategoryTheme.swift
//  JackpotTrivia
//
//  Flat category tints — Detroit palette, no heavy gradients.
//

import SwiftUI

enum CategoryTheme {
    /// Subtle flat wash behind category-specific screens.
    static func backgroundTint(for category: String) -> Color {
        accentColor(for: category).opacity(category == "Private Lounge" ? 0.12 : 0.06)
    }

    static func accentColor(for category: String) -> Color {
        switch category {
        case "Detroit Sports", "Auto City":
            return AppColors.brandPrimary
        case "Downtown & Neighborhoods", "Local Legends":
            return AppColors.textSecondary
        case "Motown & Music", "Private Lounge":
            return AppColors.brandSecondary
        default:
            return AppColors.brandPrimary
        }
    }
}
