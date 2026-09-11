//
//  LeaderboardView.swift
//  JackpotTrivia
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.analytics) private var analytics

    @State private var period: LeaderboardPeriod = .daily
    @State private var standings: [LeaderboardStanding] = []
    @State private var userRank: LeaderboardStanding?
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Period", selection: $period) {
                ForEach(LeaderboardPeriod.allCases) { item in
                    Text(item.displayName).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .appScreenHorizontalPadding()
            .padding(.vertical, AppSpacing.stackItem)

            Text(boardCaption)
                .appCaptionText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .appScreenHorizontalPadding()
                .padding(.bottom, AppSpacing.stackItem)

            if let userRank {
                yourRankCard(userRank)
                    .appScreenHorizontalPadding()
                    .padding(.bottom, AppSpacing.stackItem)
            }

            if standings.isEmpty {
                ScrollView {
                    emptyState
                }
                .refreshable {
                    await reload(forceRemote: true)
                }
            } else {
                List {
                    ForEach(standings) { standing in
                        leaderboardRow(standing)
                            .listRowBackground(
                                standing.isCurrentUser
                                    ? AppColors.brandPrimary.opacity(0.08)
                                    : AppColors.cardBackground
                            )
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await reload(forceRemote: true)
                }
            }
        }
        .brandScreenBackground()
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isRefreshing && standings.isEmpty {
                ProgressView()
                    .tint(AppColors.brandPrimary)
            }
        }
        .task {
            await reload(forceRemote: true)
        }
        .onChange(of: period) { _, newPeriod in
            analytics.track(.leaderboardViewed(period: newPeriod.rawValue))
            applyLocalStandings()
            Task { await reload(forceRemote: true) }
        }
        .onAppear {
            analytics.track(.leaderboardViewed(period: period.rawValue))
            applyLocalStandings()
        }
    }

    private var boardCaption: String {
        if LeaderboardService.usesLiveBoard {
            return "Live standings — every signed-in player who posted a score."
        }
        return "This device only. Connect Supabase to share scores with other players."
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("No scores yet")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text(
                LeaderboardService.usesLiveBoard
                    ? "Finish a round to post. Other players appear here after they post theirs."
                    : "Add SupabaseSecrets.plist so everyone’s scores land on one board."
            )
            .appBodyText()
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appScreenHorizontalPadding()
        .padding(.top, AppSpacing.section)
    }

    private func reload(forceRemote: Bool) async {
        if forceRemote {
            await MainActor.run { isRefreshing = true }
            await LeaderboardService.refreshRemote()
        }
        await MainActor.run {
            applyLocalStandings()
            isRefreshing = false
        }
    }

    private func applyLocalStandings() {
        let userID = auth.currentUser?.id
        standings = LeaderboardService.standings(for: period, currentUserID: userID)
        userRank = LeaderboardService.currentUserRank(for: period, userID: userID)
    }

    private func yourRankCard(_ standing: LeaderboardStanding) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your rank")
                    .appCaptionText()
                Text("#\(standing.rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.brandPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(standing.entry.points) pts")
                    .font(.headline)
                Text("\(standing.entry.accuracyPercent)% accuracy")
                    .appCaptionText()
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private func leaderboardRow(_ standing: LeaderboardStanding) -> some View {
        HStack(spacing: 12) {
            Text("\(standing.rank)")
                .font(.headline)
                .foregroundStyle(standing.rank <= 3 ? AppColors.brandPrimary : AppColors.textSecondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(standing.entry.displayName)
                    .font(.body)
                    .fontWeight(standing.isCurrentUser ? .semibold : .regular)
                Text("\(standing.entry.correctAnswers)/\(standing.entry.totalQuestions) correct")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text("\(standing.entry.points)")
                .font(.headline)
                .foregroundStyle(AppColors.brandPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Rank \(standing.rank), \(standing.entry.displayName), \(standing.entry.points) points"
        )
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
            .environmentObject(AuthManager.shared)
    }
}
