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

    @State private var showPremiumUpgrade = false
    @State private var pendingChallenge: FriendChallenge?

    private var dailyCompleted: Bool { DailyGameService.hasCompletedDailyToday }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                xpCard
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

                dailyCard
                    .padding(.top, AppSpacing.section)

                leaderboardCard
                    .padding(.top, AppSpacing.stackItem)

                practiceCard
                    .padding(.top, AppSpacing.stackItem)

                privateLoungeCard
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
        .background(Color(.systemBackground))
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
                        .accessibilityLabel("Account menu")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPremiumUpgrade = true
                } label: {
                    Image(systemName: "crown.fill")
                }
                .accessibilityLabel("Premium")
            }
        }
        .premiumUpgradeSheet(isPresented: $showPremiumUpgrade)
        .onAppear {
            pendingChallenge = ChallengeService.pendingChallenge
        }
    }

    private func dismissChallenge() {
        ChallengeService.clearPendingChallenge()
        pendingChallenge = nil
    }

    private var xpCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppConfig.Copy.xpBankTitle)
                .appFieldLabel()
            Text("\(PrizeWallet.pointsBalance) XP")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.brandGreen)

            if let userID = auth.currentUser?.id {
                let progress = PlayerProgressStore.progress(for: userID)
                Text("Level \(progress.level) · \(progress.totalCorrect) correct · best streak \(progress.bestStreak)")
                    .appCaptionText()
            }

            if let name = auth.currentUser?.displayName ?? auth.currentUser?.email {
                Text("Signed in as \(name)")
                    .appCaptionText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Label(AppConfig.Copy.dailyJackpotTitle, systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(AppColors.brandGreen)

            Text(AppConfig.Copy.dailyJackpotSubtitle)
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.stackItem) {
                Label("Timed", systemImage: "timer")
                Label("Tiers", systemImage: "chart.bar")
                Label("Instant feedback", systemImage: "bolt.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if dailyCompleted {
                Label("You completed today's jackpot", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.brandGreen)
            }

            Button(action: playDailyTapped) {
                Text(dailyCompleted ? "Completed for today" : "Play Today's Jackpot")
            }
            .buttonStyle(.appPrimary)
            .disabled(dailyCompleted)
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var leaderboardCard: some View {
        Button(action: onLeaderboard) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Leaderboards")
                        .font(.headline)
                    Text("Today, this week, and all-time — QuizUp-style ranks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(AppColors.brandGreen)
            }
            .padding(AppSpacing.cardInnerHorizontal)
            .frame(minHeight: AppMetrics.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var practiceCard: some View {
        Button(action: onPractice) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice mode")
                        .font(.headline)
                    Text("Pick categories, moods, and party mode — no daily limit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.cardInnerHorizontal)
            .frame(minHeight: AppMetrics.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var privateLoungeCard: some View {
        Button(action: onPrivateLounge) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private Lounge")
                        .font(.headline)
                    Text(auth.isMember
                        ? "18+ member deck — timed, no cheating."
                        : "Members only — unlock with a lounge code.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: auth.isMember ? "lock.open.fill" : "lock.fill")
                    .foregroundStyle(AppColors.brandGreen)
            }
            .padding(AppSpacing.cardInnerHorizontal)
            .frame(minHeight: AppMetrics.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var inviteCard: some View {
        Button(action: onInviteJoin) {
            Label("Enter invite code", systemImage: "ticket")
                .font(.subheadline)
                .foregroundStyle(AppColors.brandGreen)
        }
    }

    private func playDailyTapped() {
        gameSession.beginDailyRound()
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
