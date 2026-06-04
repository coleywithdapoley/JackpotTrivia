//
//  ResultsView.swift
//  JackpotTrivia
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var gameSession: GameSession
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.analytics) private var analytics
    @Environment(\.featureGates) private var featureGates
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onPlayAgain: () -> Void = {}
    var onChooseCategories: () -> Void = {}
    var onExit: () -> Void = {}

    @State private var scoreRevealed = false
    @State private var didPlayFinishHaptic = false
    @State private var showPremiumUpgrade = false
    @State private var showChallengeSheet = false
    @State private var leaderboardRank: LeaderboardStanding?

    private var totalQuestions: Int {
        gameSession.totalQuestions
    }

    private var correctAnswers: Int {
        gameSession.correctAnswers
    }

    private var hasValidRound: Bool {
        totalQuestions > 0
    }

    private var accuracyPercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
    }

    private var categoriesDisplayText: String? {
        let categories = gameSession.selectedCategories
        guard !categories.isEmpty else { return nil }
        return categories.joined(separator: ", ")
    }

    var body: some View {
        Group {
            if hasValidRound {
                resultsContent
            } else {
                emptyResultsContent
            }
        }
        .background(Color(.systemBackground))
        .premiumUpgradeSheet(isPresented: $showPremiumUpgrade)
        .sheet(isPresented: $showChallengeSheet) {
            if let challenge = currentChallenge {
                ChallengeFriendSheet(challenge: challenge)
            }
        }
        .onAppear {
            gameSession.finalizeRound(for: auth.currentUser)
            leaderboardRank = LeaderboardService.currentUserRank(
                for: .daily,
                userID: auth.currentUser?.id
            )
            revealScoreIfNeeded()
            trackQuizCompletedIfNeeded()
        }
    }

    private func trackQuizCompletedIfNeeded() {
        guard hasValidRound else { return }
        analytics.track(.quizCompleted(
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers
        ))
    }

    // MARK: - Valid results

    private var resultsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if gameSession.roundForfeited, let reason = gameSession.forfeitReason {
                    Label(reason, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .padding(.bottom, AppSpacing.stackItem)
                        .fixedSize(horizontal: false, vertical: true)
                }

                scoreSection
                    .padding(.top, AppSpacing.sectionLarge)

                summarySection
                    .padding(.top, AppSpacing.section)

                if let categoriesDisplayText {
                    categoriesSection(categoriesDisplayText)
                        .padding(.top, AppSpacing.section - 4)
                }

                pointsSection
                    .padding(.top, AppSpacing.section)

                breakdownSection
                    .padding(.top, AppSpacing.section + 4)

                if let leaderboardRank {
                    rankSection(leaderboardRank)
                        .padding(.top, AppSpacing.stackItem)
                }

                if hasValidRound {
                    socialSection
                        .padding(.top, AppSpacing.section)
                }

                if gameSession.roundKind == .dailyJackpot {
                    dailyCompleteBanner
                        .padding(.top, AppSpacing.stackItem)
                }

                if featureGates.isFreeTier {
                    premiumUpgradeHint
                        .padding(.top, AppSpacing.section)
                }
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            actionsSection
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.bottomBarTop)
                .padding(.bottom, AppSpacing.screenBottom)
                .background(Color(.systemBackground))
        }
    }

    private var emptyResultsContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    Text("No questions answered")
                        .appScreenSubtitle()
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Start a round from category selection to see your results here.")
                        .appBodyText()
                        .multilineTextAlignment(.center)
                }
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.sectionLarge)
                .frame(maxWidth: .infinity)
            }

            actionsSection
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.bottomBarTop)
                .padding(.bottom, AppSpacing.screenBottom)
        }
    }

    // MARK: - Sections

    private var scoreSection: some View {
        VStack(spacing: AppSpacing.labelToField) {
            Text("Results")
                .appScreenSubtitle()
                .accessibilityAddTraits(.isHeader)

            // User-facing — localizable; scales with Dynamic Type
            Text("\(correctAnswers) / \(totalQuestions)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(AppColors.royalBlue)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .scaleEffect(scoreRevealed ? 1 : (reduceMotion ? 1 : 0.92))
                .opacity(scoreRevealed ? 1 : 0)
                .animation(AppAnimation.quick, value: scoreRevealed)
                .accessibilityHidden(true)

            Text("Correct Answers")
                .appHelperText()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(correctAnswers) out of \(totalQuestions) correct answers")
    }

    @ViewBuilder
    private var summarySection: some View {
        if accuracyPercentage >= AppConfig.Copy.highScoreAccuracyThreshold {
            Text("Nice work! You really know your stuff.")
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("Good effort! Want to try again and beat your score?")
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func categoriesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Categories")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Categories played: \(text)")
    }

    /// Generic upgrade copy only — no purchase UI yet.
    private var premiumUpgradeHint: some View {
        Button {
            showPremiumUpgrade = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(AppColors.royalBlue)
                Text("Enjoyed this game? Unlock Premium for more questions and categories.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.royalBlue)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.royalBlue)
            }
            .padding(AppSpacing.cardInnerHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.royalBlue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Upgrade to Premium")
        .accessibilityHint("Opens Premium benefits")
    }

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Points earned")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text("\(gameSession.roundPoints) pts")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.brandGreen)

            Text("Wallet balance: \(PrizeWallet.pointsBalance) pts (≈ \(PrizeWallet.estimatedCashDisplay) demo)")
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)

            Text(AppConfig.Copy.prizeDisclaimer)
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Points earned \(gameSession.roundPoints). Wallet balance \(PrizeWallet.pointsBalance) points.")
    }

    private var currentChallenge: FriendChallenge? {
        guard hasValidRound else { return nil }
        let name = auth.currentUser?.displayName ?? auth.currentUser?.email ?? "Player"
        return ChallengeService.makeChallenge(
            challengerName: name,
            points: gameSession.roundPoints,
            correctAnswers: gameSession.correctAnswers,
            totalQuestions: gameSession.totalQuestions
        )
    }

    private var shareText: String {
        SocialShareService.resultsShareText(
            session: gameSession,
            user: auth.currentUser,
            rank: leaderboardRank
        )
    }

    private func rankSection(_ standing: LeaderboardStanding) -> some View {
        Label(
            "You're #\(standing.rank) today with \(standing.entry.points) pts",
            systemImage: "trophy.fill"
        )
        .font(.subheadline)
        .foregroundStyle(AppColors.brandGreen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var socialSection: some View {
        VStack(spacing: AppSpacing.stackItem) {
            ShareLink(item: shareText) {
                Label("Share my score", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.appSecondary)
            .simultaneousGesture(TapGesture().onEnded {
                analytics.track(.scoreShared(points: gameSession.roundPoints))
            })

            Button {
                showChallengeSheet = true
                analytics.track(.challengeShared(points: gameSession.roundPoints))
            } label: {
                Label("Challenge a friend", systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.appSecondary)
        }
    }

    private var dailyCompleteBanner: some View {
        Label("Today's jackpot recorded — come back tomorrow.", systemImage: "calendar.badge.checkmark")
            .font(.subheadline)
            .foregroundStyle(AppColors.brandGreen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.cardInnerHorizontal)
            .background(AppColors.brandGreen.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Breakdown")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: AppSpacing.stackItem) {
                breakdownStat(title: "Total", value: "\(totalQuestions)")
                breakdownStat(title: "Correct", value: "\(correctAnswers)")
                breakdownStat(title: "Accuracy", value: "\(accuracyPercentage)%")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func breakdownStat(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.royalBlue)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: AppMetrics.minimumTouchTarget)
        .padding(.vertical, 14)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private var actionsSection: some View {
        VStack(spacing: AppSpacing.stackItem) {
            if hasValidRound {
                let dailyDone = gameSession.roundKind == .dailyJackpot && DailyGameService.hasCompletedDailyToday
                Button(action: playAgainTapped) {
                    Text(dailyDone ? "Back to Home" : "Play Again")
                }
                .buttonStyle(.appPrimary)
                .accessibilityLabel(dailyDone ? "Back to Home" : "Play Again")
                .accessibilityHint(
                    dailyDone
                        ? "Daily jackpot already completed"
                        : "Starts a new round with the same categories"
                )
            }

            Group {
                if hasValidRound {
                    Button(action: chooseCategoriesTapped) {
                        Text("Choose Categories")
                    }
                    .buttonStyle(.appSecondary)
                } else {
                    Button(action: chooseCategoriesTapped) {
                        Text("Choose Categories")
                    }
                    .buttonStyle(.appPrimary)
                }
            }
            .accessibilityLabel("Choose Categories")
            .accessibilityHint("Returns to category selection")

            Button(action: exitTapped) {
                Text("Exit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppMetrics.minimumTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Exit")
            .accessibilityHint("Leaves the trivia flow and returns to the start")
        }
    }

    // MARK: - Actions

    private func revealScoreIfNeeded() {
        guard hasValidRound else { return }
        guard !didPlayFinishHaptic else {
            scoreRevealed = true
            return
        }
        didPlayFinishHaptic = true
        Haptics.success()
        scoreRevealed = true
    }

    private func playAgainTapped() {
        gameSession.resetForReplay()
        scoreRevealed = false
        didPlayFinishHaptic = false
        onPlayAgain()
    }

    private func chooseCategoriesTapped() {
        onChooseCategories()
    }

    private func exitTapped() {
        onExit()
    }
}

// MARK: - Previews

#Preview("Strong score") {
    let session = GameSession()
    session.selectedCategories = ["Science", "History", "Sports"]
    session.totalQuestions = 10
    session.correctAnswers = 8
    return ResultsView()
        .environmentObject(session)
        .environmentObject(AuthManager.shared)
}

#Preview("Empty round") {
    ResultsView()
        .environmentObject(GameSession())
}
