//
//  ResultsView.swift
//  JackpotTrivia
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var gameSession: GameSession
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.analytics) private var analytics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onPlayAgain: () -> Void = {}
    var onChooseCategories: () -> Void = {}
    var onExit: () -> Void = {}

    @State private var scoreRevealed = false
    @State private var didPlayFinishHaptic = false
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

    private var resultsHeadline: String {
        switch gameSession.roundKind {
        case .dailyJackpot:
            return AppConfig.Copy.resultsHeadlineDaily
        default:
            return AppConfig.Copy.resultsHeadlinePractice
        }
    }

    private var secondaryActionTitle: String {
        gameSession.roundKind == .dailyJackpot ? "Back to Hub" : "Pick Categories"
    }

    var body: some View {
        Group {
            if hasValidRound {
                resultsContent
            } else {
                emptyResultsContent
            }
        }
        .brandScreenBackground()
        .sheet(isPresented: $showChallengeSheet) {
            if let challenge = currentChallenge {
                ChallengeFriendSheet(challenge: challenge)
            }
        }
        .onAppear {
            gameSession.finalizeRound(for: auth.currentUser)
            refreshLocalRank()
            revealScoreIfNeeded()
            trackQuizCompletedIfNeeded()
            Task { await refreshLiveRank() }
        }
    }

    private func trackQuizCompletedIfNeeded() {
        guard hasValidRound else { return }
        analytics.track(.quizCompleted(
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers
        ))
    }

    private func refreshLocalRank() {
        leaderboardRank = LeaderboardService.currentUserRank(
            for: .daily,
            userID: auth.currentUser?.id
        )
    }

    private func refreshLiveRank() async {
        await SupabaseSyncService.flushPending()
        await LeaderboardService.refreshRemote()
        await MainActor.run { refreshLocalRank() }
    }

    // MARK: - Valid results

    private var resultsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if gameSession.roundForfeited, let reason = gameSession.forfeitReason {
                    Label(reason, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.brandSecondary)
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
                .background(AppColors.brandBackground)
        }
    }

    private var emptyResultsContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(AppColors.textSecondary)
                        .accessibilityHidden(true)

                    Text(AppConfig.Copy.resultsEmptyTitle)
                        .appScreenSubtitle()
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(AppConfig.Copy.resultsEmptyMessage)
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
            Text(resultsHeadline)
                .appScreenSubtitle()
                .accessibilityAddTraits(.isHeader)

            // User-facing — localizable; scales with Dynamic Type
            Text("\(correctAnswers) / \(totalQuestions)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(AppColors.brandPrimary)
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
        let isStrong = accuracyPercentage >= AppConfig.Copy.highScoreAccuracyThreshold
        let message: String = {
            if gameSession.roundKind == .dailyJackpot {
                return isStrong
                    ? AppConfig.Copy.resultsDailyHighScore
                    : AppConfig.Copy.resultsDailyEncourage
            }
            return isStrong
                ? AppConfig.Copy.resultsHighScoreMessage
                : AppConfig.Copy.resultsEncourageMessage
        }()

        Text(message)
            .font(.body)
            .foregroundStyle(AppColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoriesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Categories")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Categories played: \(text)")
    }

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Round score")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text("\(gameSession.roundPoints) pts")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.brandPrimary)

            Text("\(gameSession.correctAnswers)/\(gameSession.totalQuestions) correct · 100 pts each")
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)

            Text("\(AppConfig.Copy.xpBankTitle): \(PrizeWallet.pointsBalance) XP")
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)

            Text(AppConfig.Copy.prizeDisclaimer)
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Round score \(gameSession.roundPoints) points. \(gameSession.correctAnswers) of \(gameSession.totalQuestions) correct. Score bank \(PrizeWallet.pointsBalance) XP.")
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
        .foregroundStyle(AppColors.brandPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandPrimary.opacity(0.08))
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
        Label(AppConfig.Copy.resultsDailyBanner, systemImage: "calendar.badge.checkmark")
            .font(.subheadline)
            .foregroundStyle(AppColors.brandPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.cardInnerHorizontal)
            .background(AppColors.brandPrimary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Breakdown")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textSecondary)
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
                .foregroundStyle(AppColors.brandPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
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
                        Text(secondaryActionTitle)
                    }
                    .buttonStyle(.appSecondary)
                } else {
                    Button(action: chooseCategoriesTapped) {
                        Text(secondaryActionTitle)
                    }
                    .buttonStyle(.appPrimary)
                }
            }
            .accessibilityLabel(secondaryActionTitle)
            .accessibilityHint(
                gameSession.roundKind == .dailyJackpot
                    ? "Returns to the home hub"
                    : "Returns to category selection"
            )

            Button(action: exitTapped) {
                Text("Exit")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
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
    session.selectedCategories = ["Auto City", "Local Legends", "Detroit Sports"]
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
