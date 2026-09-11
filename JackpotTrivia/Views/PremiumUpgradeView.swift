//
//  PremiumUpgradeView.swift
//  JackpotTrivia
//
//  External-beta safe: no purchase UI and no mock unlock.
//  StoreKit comes later. Admin can still preview this screen.
//

import SwiftUI

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureGates) private var featureGates

    private let freeGates = FeatureGates(tier: .free)
    private let premiumGates = FeatureGates(tier: .premium)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, AppSpacing.section)

                benefitsSection
                    .padding(.top, AppSpacing.section)

                comparisonSection
                    .padding(.top, AppSpacing.section)

                legalNote
                    .padding(.top, AppSpacing.section)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .brandScreenBackground()
        .safeAreaInset(edge: .bottom) {
            Button("Close") { dismiss() }
                .buttonStyle(.appPrimary)
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.bottomBarTop)
                .padding(.bottom, AppSpacing.screenBottom)
                .background(AppColors.brandBackground)
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppSpacing.stackItem) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.brandSecondary)
                .accessibilityHidden(true)

            Text("Premium is coming later")
                .appScreenTitle()
                .frame(maxWidth: .infinity)

            Text("This beta is free to play. There is nothing to buy in the app. XP has no cash value.")
                .appBodyText()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Planned for a future update")
                .appFieldLabel()

            benefitRow(icon: "questionmark.circle.fill", title: "Longer rounds", detail: "Up to \(premiumGates.maxQuestionsPerGame) questions per game (Free: \(freeGates.maxQuestionsPerGame))")
            benefitRow(icon: "square.grid.2x2.fill", title: "All categories", detail: "Pick as many categories as you want each round")
            benefitRow(icon: "sparkles", title: "Party mode", detail: "Full random play across every category")
        }
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.brandSecondary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("This beta")
                .appFieldLabel()

            HStack(spacing: AppSpacing.stackItem) {
                tierCard(title: "Free play", gates: freeGates, isHighlighted: true)
                tierCard(title: "Later", gates: premiumGates, isHighlighted: false)
            }
        }
    }

    private func tierCard(title: String, gates: FeatureGates, isHighlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isHighlighted ? AppColors.brandSecondary : AppColors.textPrimary)

            Text("\(gates.maxQuestionsPerGame) questions")
                .font(.caption)
            Text(gates.maxCategoriesSelectable == Int.max ? "Unlimited categories" : "\(gates.maxCategoriesSelectable) categories")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardInnerHorizontal)
        .padding(.vertical, 12)
        .background(isHighlighted ? AppColors.brandSecondary.opacity(0.12) : AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(isHighlighted ? AppColors.brandSecondary : AppColors.cardBorder, lineWidth: isHighlighted ? 2 : 1)
        )
    }

    private var legalNote: some View {
        Text("No in-app purchases, subscriptions, or real-money prizes. If Premium ships later, it will use Apple’s App Store billing.")
            .appCaptionText()
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct PremiumUpgradeScreen: View {
    var body: some View {
        NavigationStack {
            PremiumUpgradeView()
        }
    }
}

extension View {
    func premiumUpgradeSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            PremiumUpgradeScreen()
        }
    }
}

#Preview {
    PremiumUpgradeScreen()
        .environment(\.featureGates, FeatureGates(tier: .free))
}
