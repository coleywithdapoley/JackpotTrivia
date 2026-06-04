//
//  PremiumUpgradeView.swift
//  JackpotTrivia
//
//  Mock paywall UI — no StoreKit. Replace primary action with StoreView when ready.
//

import SwiftUI

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureGates) private var featureGates

    @State private var showDemoUnlockedAlert = false

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
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            actionBar
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.bottomBarTop)
                .padding(.bottom, AppSpacing.screenBottom)
                .background(Color(.systemBackground))
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .alert("Premium (Demo)", isPresented: $showDemoUnlockedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Demo Premium is on for this device. Free-tier limits are lifted — start a new round to see more questions and categories.")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppSpacing.stackItem) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.royalBlue)
                .accessibilityHidden(true)

            Text("Upgrade to Premium")
                .appScreenTitle()
                .frame(maxWidth: .infinity)

            Text("More questions, every category, and the full party experience — built for friend groups and game night.")
                .appBodyText()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("What's included")
                .appFieldLabel()

            benefitRow(icon: "questionmark.circle.fill", title: "Longer rounds", detail: "Up to \(premiumGates.maxQuestionsPerGame) questions per game (Free: \(freeGates.maxQuestionsPerGame))")
            benefitRow(icon: "square.grid.2x2.fill", title: "All categories", detail: "Pick as many categories as you want each round")
            benefitRow(icon: "sparkles", title: "Party mode", detail: "Full random play across every category")
            benefitRow(icon: "face.smiling.fill", title: "All moods", detail: "Date Night, Debate Mode, Family Game Night, and more")
            benefitRow(icon: "rectangle.on.rectangle.angled.fill", title: "No ads", detail: "Cleaner experience without ad placeholders")
        }
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.royalBlue)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            Text("Free vs Premium")
                .appFieldLabel()

            HStack(spacing: AppSpacing.stackItem) {
                tierCard(title: "Free", gates: freeGates, isHighlighted: featureGates.isFreeTier)
                tierCard(title: "Premium", gates: premiumGates, isHighlighted: !featureGates.isFreeTier)
            }
        }
    }

    private func tierCard(title: String, gates: FeatureGates, isHighlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isHighlighted ? AppColors.royalBlue : .primary)

            Text("\(gates.maxQuestionsPerGame) questions")
                .font(.caption)
            Text(gates.maxCategoriesSelectable == Int.max ? "Unlimited categories" : "\(gates.maxCategoriesSelectable) categories")
                .font(.caption)
            Text(gates.showsAds ? "Ads" : "No ads")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardInnerHorizontal)
        .padding(.vertical, 12)
        .background(isHighlighted ? AppColors.royalBlue.opacity(0.1) : AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(isHighlighted ? AppColors.royalBlue : AppColors.cardBorder, lineWidth: isHighlighted ? 2 : 1)
        )
    }

    private var legalNote: some View {
        Text("Subscriptions and one-time purchases will be offered through the App Store when billing is enabled. No payment is collected on this screen.")
            .appCaptionText()
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionBar: some View {
        VStack(spacing: AppSpacing.stackItem) {
            // TODO: Replace with StoreKit 2 StoreView / purchase flow.
            Button(action: unlockPremiumTapped) {
                Text("Unlock Premium")
            }
            .buttonStyle(.appPrimary)
            .accessibilityHint("Mock only — enables demo premium on this device")

            Button(action: tryDemoTapped) {
                Text("Try Premium (Demo)")
            }
            .buttonStyle(.appSecondary)

            Button("Not now") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppMetrics.minimumTouchTarget)
        }
    }

    // MARK: - Actions

    private func unlockPremiumTapped() {
        // Placeholder for StoreKit — same as demo for now.
        tryDemoTapped()
    }

    private func tryDemoTapped() {
        PremiumAccessStore.isMockUnlocked = true
        showDemoUnlockedAlert = true
    }
}

// MARK: - Presentation

/// Wraps the mock paywall in a `NavigationStack` for sheets (avoids nested stacks when pushing from admin).
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
