//
//  DailyJackpotView.swift
//  JackpotTrivia
//

import SwiftUI

struct DailyJackpotView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var gameSession: GameSession
    @Environment(\.featureGates) private var featureGates

    var onPlayDaily: () -> Void = {}
    var onPractice: () -> Void = {}
    var onInviteJoin: () -> Void = {}
    var onLeaderboard: () -> Void = {}
    var onPrivateLounge: () -> Void = {}
    var onMembership: () -> Void = {}

    @State private var pendingChallenge: FriendChallenge?

    private var dailyCompleted: Bool { DailyGameService.hasCompletedDailyToday }

    private var effectiveDailyQuestionCount: Int {
        min(AppConfig.dailyQuestionCount, featureGates.maxQuestionsPerGame)
    }

    private var hubDailySubtitleText: String {
        if featureGates.isFreeTier, effectiveDailyQuestionCount < AppConfig.dailyQuestionCount {
            return "\(effectiveDailyQuestionCount) questions · free tier · once per day."
        }
        return AppConfig.Copy.hubDailySubtitle
    }

    private var playerProgress: PlayerProgress? {
        guard let userID = auth.currentUser?.id else { return nil }
        return PlayerProgressStore.progress(for: userID)
    }

    private var lastDailyEntry: LeaderboardEntry? {
        guard let userID = auth.currentUser?.id else { return nil }
        let todayKey = DailyGameService.dayKey()
        return LeaderboardService.allEntries()
            .filter { entry in
                entry.userID == userID
                    && entry.roundKind == .dailyJackpot
                    && DailyGameService.dayKey(for: entry.recordedAt) == todayKey
            }
            .max(by: { $0.recordedAt < $1.recordedAt })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                scoreboardHeader
                    .padding(.top, AppSpacing.section)

                if let pendingChallenge {
                    PendingChallengeBanner(
                        challenge: pendingChallenge,
                        onDismiss: dismissChallenge,
                        onAccept: {
                            dismissChallenge()
                            playDailyTapped()
                        }
                    )
                    .padding(.top, AppSpacing.section)
                }

                jackpotHero
                    .padding(.top, AppSpacing.sectionLarge)

                secondaryActions
                    .padding(.top, AppSpacing.section)

                Button(action: onLeaderboard) {
                    Text(AppConfig.Copy.hubLeaderboardLink)
                        .font(.footnote)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppMetrics.minimumTouchTarget)
                .padding(.top, AppSpacing.stackItem)

                if AppConfig.requiresInviteAfterAuth {
                    inviteCard
                        .padding(.top, AppSpacing.stackItem)
                }

                Text(AppConfig.Copy.prizeDisclaimer)
                    .appCaptionText()
                    .padding(.top, AppSpacing.section)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .brandScreenBackground()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Membership") {
                        onMembership()
                    }
                    Button("Sign out", role: .destructive) {
                        auth.signOut()
                    }
                } label: {
                    Image(systemName: "person.circle")
                        .font(.body)
                        .foregroundStyle(AppColors.textTertiary)
                        .accessibilityLabel("Account menu")
                }
            }
        }
        .onAppear {
            pendingChallenge = ChallengeService.pendingChallenge
        }
        .task {
            await QuestionRepository.shared.refreshCatalog(
                accessToken: SupabaseSessionStore.current?.accessToken
            )
        }
    }

    // MARK: - Top scoreboard

    private var scoreboardHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            HStack(alignment: .top, spacing: AppSpacing.stackItem) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppConfig.Copy.hubHeadline)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(AppConfig.Copy.hubGreeting)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.brandPrimary.opacity(0.55))
                    .accessibilityHidden(true)
            }

            HStack(spacing: AppSpacing.stackItem) {
                statChip(
                    label: "XP",
                    value: "\(PrizeWallet.pointsBalance)",
                    accent: AppColors.brandPrimary
                )

                if let progress = playerProgress {
                    statChip(
                        label: "Best streak",
                        value: "\(progress.bestStreak)",
                        accent: AppColors.brandPrimary
                    )
                }

                if let lastDailyEntry {
                    statChip(
                        label: "Today",
                        value: "\(lastDailyEntry.correctAnswers)/\(lastDailyEntry.totalQuestions)",
                        accent: AppColors.brandPrimary
                    )
                }
            }

            if let name = auth.currentUser?.displayName ?? auth.currentUser?.email {
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private func statChip(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppColors.brandBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Dominant daily CTA

    private var jackpotHero: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text(AppConfig.Copy.hubDailyEyebrow)
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.2)
                .foregroundStyle(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)

            Text(AppConfig.Copy.hubDailyTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            Text(hubDailySubtitleText)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if dailyCompleted {
                VStack(spacing: AppSpacing.labelToField) {
                    Label(AppConfig.Copy.hubDailyCompletedNote, systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.brandPrimary)
                        .frame(maxWidth: .infinity)

                    Text(AppConfig.Copy.hubDailyCompletedCTA)
                        .font(.headline)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppMetrics.primaryButtonMinHeight)
                        .background(AppColors.primaryButtonDisabled.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                        .accessibilityLabel("Today's jackpot complete. Come back tomorrow.")
                }
                .padding(.top, 4)
            } else {
                Button(action: playDailyTapped) {
                    Text(AppConfig.Copy.hubDailyCTA)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.appPrimary)
                .controlSize(.large)
                .frame(minHeight: 64)
                .padding(.top, 4)
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .padding(.vertical, AppSpacing.section + 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .fill(AppColors.brandSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                        .strokeBorder(
                            AppColors.brandPrimary.opacity(dailyCompleted ? 0.2 : 0.65),
                            lineWidth: dailyCompleted ? 1 : 2
                        )
                )
        )
    }

    // MARK: - Secondary actions

    private var secondaryActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text(AppConfig.Copy.hubSecondarySectionTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.bottom, 2)

            pickupRoundsCard
            membersClubCard
        }
    }

    private var pickupRoundsCard: some View {
        Button(action: onPractice) {
            HStack(spacing: 14) {
                Image(systemName: "shuffle")
                    .font(.body)
                    .foregroundStyle(AppColors.brandPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppConfig.Copy.hubPickupRoundsTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(AppConfig.Copy.hubPickupRoundsSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.cardInnerHorizontal)
            .padding(.vertical, 14)
            .frame(minHeight: AppMetrics.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .background(AppColors.brandSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var membersClubCard: some View {
        Button(action: onPrivateLounge) {
            HStack(spacing: 14) {
                Image(systemName: auth.isMember ? "lock.open.fill" : "lock.fill")
                    .font(.body)
                    .foregroundStyle(AppColors.brandSecondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppConfig.Copy.hubMembersClubTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(auth.isMember
                        ? AppConfig.Copy.hubMembersClubSubtitleMember
                        : AppConfig.Copy.hubMembersClubSubtitleLocked)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.brandSecondary.opacity(0.6))
            }
            .padding(.horizontal, AppSpacing.cardInnerHorizontal)
            .padding(.vertical, 14)
            .frame(minHeight: AppMetrics.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .background(AppColors.brandSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(AppColors.brandSecondary.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var inviteCard: some View {
        Button(action: onInviteJoin) {
            Label("Enter invite code", systemImage: "ticket")
                .font(.footnote)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    // MARK: - Actions

    private func dismissChallenge() {
        ChallengeService.clearPendingChallenge()
        pendingChallenge = nil
    }

    private func playDailyTapped() {
        gameSession.beginDailyRound()
        featureGates.applyQuestionLimit(to: gameSession)
        onPlayDaily()
    }
}

#Preview {
    NavigationStack {
        DailyJackpotView()
            .environmentObject(AuthManager.shared)
            .environmentObject(GameSession())
    }
}
