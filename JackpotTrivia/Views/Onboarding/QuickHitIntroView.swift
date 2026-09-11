//
//  QuickHitIntroView.swift
//  JackpotTrivia
//

import SwiftUI

struct QuickHitIntroView: View {
    var onPlaySample: () -> Void = {}
    var onSignIn: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, AppSpacing.heroTop)

                highlights
                    .padding(.top, AppSpacing.section)

                Button(action: onPlaySample) {
                    Text(AppConfig.Copy.quickHitPlayCTA)
                }
                .buttonStyle(.appPrimary)
                .padding(.top, AppSpacing.sectionLarge)

                Button(action: onSignIn) {
                    Text(AppConfig.Copy.quickHitSignInPrompt)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: AppMetrics.minimumTouchTarget)
                .padding(.top, AppSpacing.stackItem)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .brandScreenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text(AppConfig.Copy.quickHitEyebrow)
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.4)
                .foregroundStyle(AppColors.brandPrimary)

            Image("AppLogoMark")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)

            Text(AppConfig.Copy.quickHitTitle)
                .appScreenTitle()

            Text(AppConfig.Copy.quickHitSubtitle)
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
    }

    private var highlights: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            highlightRow(icon: "clock.fill", text: AppConfig.Copy.quickHitHighlightDuration)
            highlightRow(icon: "person.crop.circle.badge.checkmark", text: AppConfig.Copy.quickHitHighlightNoLogin)
            highlightRow(icon: "building.2.fill", text: AppConfig.Copy.quickHitHighlightCategories)
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .padding(.vertical, AppSpacing.cardInnerVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.brandSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(AppColors.brandPrimary.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private func highlightRow(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(AppColors.textPrimary)
            .labelStyle(.titleAndIcon)
    }
}

#Preview {
    QuickHitIntroView()
}
