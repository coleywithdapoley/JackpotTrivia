//
//  CategoryArtwork.swift
//  JackpotTrivia
//

import SwiftUI

/// Category thumbnail — asset image when available, emoji fallback otherwise.
struct CategoryArtwork: View {
    let category: String
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 8
    /// Slightly softens unselected artwork so text stays the focus.
    var isDimmed: Bool = false

    var body: some View {
        Group {
            if let asset = AppConfig.imageAsset(forCategory: category) {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .saturation(isDimmed ? 0.75 : 0.9)
                    .brightness(isDimmed ? -0.06 : -0.02)
            } else if let emoji = AppConfig.emoji(forCategory: category) {
                Text(emoji)
                    .font(.system(size: size * 0.45))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CategoryTheme.accentColor(for: category).opacity(0.12))
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.brandSurface)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}
