//
//  DesignSystem.swift
//  JackpotTrivia
//
//  Brand visual identity — black surfaces, green CTAs, purple club accents.
//

import SwiftUI

// MARK: - Colors

enum AppColors {
    // MARK: Brand palette

    /// Soft black app chrome (#0A0A0A) — easier on eyes than pure black.
    static let brandBackground = Color("BrandBackground")
    /// Elevated cards and inputs (#1A1A1A).
    static let brandSurface = Color("BrandSurface")
    /// Green — primary CTAs, progress, highlights (#00C853).
    static let brandPrimary = Color("BrandPrimary")
    /// Purple — premium / club / lounge accents (#9333EA).
    static let brandSecondary = Color("BrandSecondary")

    /// Primary body text on dark surfaces (#E6E6E6).
    static let textPrimary = Color("BrandTextPrimary")
    /// Supporting labels and metadata — bumped for WCAG AA on dark (#ADB5BD).
    static let textSecondary = Color("BrandTextSecondary")
    /// Tertiary captions (#949BA8).
    static let textTertiary = Color(red: 148 / 255, green: 155 / 255, blue: 168 / 255)

    /// Hairline dividers and card outlines (#3A3A3A).
    static let subtleBorder = Color("BrandSubtleBorder")
    /// Validation and destructive feedback (#EF4444).
    static let error = Color("BrandError")
    /// Correct answers and positive states (green).
    static let success = brandPrimary

    /// Green used for labels/icons on dark — full brand hue, slightly softened.
    static let brandPrimaryOnDark = brandPrimary.opacity(0.92)
    /// Selected card wash — visible but low-glare.
    static let brandPrimarySoft = brandPrimary.opacity(0.14)
    /// Purple icons on dark backgrounds.
    static let brandSecondaryOnDark = brandSecondary.opacity(0.95)

    /// Dark text on green primary buttons — meets contrast on brandPrimary fill.
    static let textOnPrimary = Color(red: 0, green: 0, blue: 0)
    static let primaryButtonDisabled = Color(red: 64 / 255, green: 64 / 255, blue: 64 / 255)
    static let primaryButtonDisabledLabel = Color(red: 160 / 255, green: 160 / 255, blue: 160 / 255)

    // MARK: Backward-compatible aliases

    static let brandGreen = brandPrimary
    static let royalBlue = brandPrimary
    static let cardBackground = brandSurface
    static let cardBorder = subtleBorder
}

extension Color {
    static let appAccent = AppColors.brandPrimary
    static let appClubAccent = AppColors.brandSecondary
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
        font(.largeTitle).fontWeight(.bold).foregroundStyle(AppColors.textPrimary)
    }

    func appScreenSubtitle() -> some View {
        font(.title2).fontWeight(.semibold).foregroundStyle(AppColors.textPrimary)
    }

    func appBodyText() -> some View {
        font(.body)
            .foregroundStyle(AppColors.textSecondary)
            .lineSpacing(4)
    }

    func appFieldLabel() -> some View {
        font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.textPrimary)
    }

    func appHelperText() -> some View {
        font(.footnote)
            .foregroundStyle(AppColors.textSecondary)
            .lineSpacing(3)
    }

    func appCaptionText() -> some View {
        font(.footnote)
            .foregroundStyle(AppColors.textTertiary)
            .lineSpacing(3)
    }

    func appScreenHorizontalPadding() -> some View {
        padding(.horizontal, AppSpacing.screenHorizontal)
    }

    /// Full-screen dark background with a very subtle top green wash.
    func brandScreenBackground() -> some View {
        background {
            ZStack {
                AppColors.brandBackground
                LinearGradient(
                    colors: [AppColors.brandPrimary.opacity(0.04), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.4)
                )
            }
            .ignoresSafeArea()
        }
    }

    /// Standard elevated card surface for lists and panels.
    func appCardSurface() -> some View {
        background(AppColors.brandSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
            )
    }

    /// Selectable list/card row — green wash + border when selected; works with checkmarks for a11y.
    func appSelectableCard(isSelected: Bool) -> some View {
        let borderWidth: CGFloat = isSelected ? 2 : 1
        return background(isSelected ? AppColors.brandPrimarySoft : AppColors.brandSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.brandPrimaryOnDark : AppColors.subtleBorder,
                        lineWidth: borderWidth
                    )
            )
    }
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? AppColors.textOnPrimary : AppColors.primaryButtonDisabledLabel)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppMetrics.primaryButtonMinHeight)
            .background(isEnabled ? AppColors.brandPrimary : AppColors.primaryButtonDisabled)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? AppColors.brandPrimary : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppMetrics.secondaryButtonMinHeight)
            .background(AppColors.brandSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isEnabled ? AppColors.brandPrimary : AppColors.subtleBorder,
                        lineWidth: 1.5
                    )
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

/// Purple-outline style for club / membership secondary actions.
struct ClubButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? AppColors.brandSecondary : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppMetrics.secondaryButtonMinHeight)
            .background(AppColors.brandSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isEnabled ? AppColors.brandSecondary : AppColors.subtleBorder,
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

extension ButtonStyle where Self == ClubButtonStyle {
    static var appClub: ClubButtonStyle { ClubButtonStyle() }
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
