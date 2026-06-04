//
//  DesignSystem.swift
//  JackpotTrivia
//

import SwiftUI

// MARK: - Colors

enum AppColors {
    /// Primary brand accent (green) — sourced from AppConfig.
    static let brandGreen = AppConfig.primaryAccentColor
    /// Backward-compatible alias used across existing views.
    static let royalBlue = brandGreen
    static let primaryButtonDisabled = Color(.systemGray3)
    static let cardBackground = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator)
}

extension Color {
    /// Backward-compatible alias for `AppColors.royalBlue`.
    static let appAccent = AppColors.royalBlue
}

// MARK: - Spacing & metrics

enum AppSpacing {
    static let screenHorizontal: CGFloat = 24
    static let screenBottom: CGFloat = 16
    static let section: CGFloat = 24
    static let sectionLarge: CGFloat = 32
    static let heroTop: CGFloat = 48
    static let stackItem: CGFloat = 12
    static let labelToField: CGFloat = 8
    static let fieldToAction: CGFloat = 16
    static let bottomBarTop: CGFloat = 12
    static let cardInnerHorizontal: CGFloat = 16
    static let cardInnerVertical: CGFloat = 16
}

enum AppMetrics {
    static let cornerRadius: CGFloat = 12
    /// HIG minimum touch target (44pt).
    static let minimumTouchTarget: CGFloat = 44
    static let primaryButtonMinHeight: CGFloat = 50
    static let secondaryButtonMinHeight: CGFloat = 50
    static let cardMinHeight: CGFloat = 52
}

// MARK: - Typography (View modifiers)

extension View {
    func appScreenTitle() -> some View {
        font(.largeTitle).fontWeight(.bold).foregroundStyle(.primary)
    }

    func appScreenSubtitle() -> some View {
        font(.title2).fontWeight(.semibold).foregroundStyle(.primary)
    }

    func appBodyText() -> some View {
        font(.body).foregroundStyle(.secondary)
    }

    func appFieldLabel() -> some View {
        font(.subheadline).fontWeight(.medium).foregroundStyle(.primary)
    }

    func appHelperText() -> some View {
        font(.footnote).foregroundStyle(.secondary)
    }

    func appCaptionText() -> some View {
        font(.caption).foregroundStyle(.tertiary)
    }

    func appScreenHorizontalPadding() -> some View {
        padding(.horizontal, AppSpacing.screenHorizontal)
    }
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppMetrics.primaryButtonMinHeight)
            .background(isEnabled ? AppColors.royalBlue : AppColors.primaryButtonDisabled)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? AppColors.royalBlue : Color(.secondaryLabel))
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppMetrics.secondaryButtonMinHeight)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isEnabled ? AppColors.royalBlue : Color(.separator),
                        lineWidth: 1.5
                    )
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var appPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var appSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Motion

enum AppAnimation {
    /// Short UI transitions (~200ms). SwiftUI respects Reduce Motion when applied via `.animation(_:value:)`.
    static var quick: Animation {
        .easeOut(duration: 0.2)
    }
}

extension View {
    /// Subtle press/selection scale; skipped when Reduce Motion is on.
    @ViewBuilder
    func appSelectionScale(isActive: Bool, reduceMotion: Bool) -> some View {
        if reduceMotion {
            self
        } else {
            scaleEffect(isActive ? 1.02 : 1.0)
                .animation(AppAnimation.quick, value: isActive)
        }
    }
}
