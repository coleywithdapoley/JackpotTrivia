//
//  LeaderboardView.swift
//  JackpotTrivia
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.analytics) private var analytics

    @State private var period: LeaderboardPeriod = .daily

    private var standings: [LeaderboardStanding] {
        LeaderboardService.standings(
            for: period,
            currentUserID: auth.currentUser?.id
        )
    }

    private var userRank: LeaderboardStanding? {
        LeaderboardService.currentUserRank(for: period, userID: auth.currentUser?.id)
    }

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

            if let userRank {
                yourRankCard(userRank)
                    .appScreenHorizontalPadding()
                    .padding(.bottom, AppSpacing.stackItem)
            }

            List {
                ForEach(standings) { standing in
                    leaderboardRow(standing)
                        .listRowBackground(
                            standing.isCurrentUser
                                ? AppColors.brandGreen.opacity(0.08)
                                : AppColors.cardBackground
                        )
                }
            }
            .listStyle(.plain)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analytics.track(.leaderboardViewed(period: period.rawValue))
        }
        .onChange(of: period) { _, newPeriod in
            analytics.track(.leaderboardViewed(period: newPeriod.rawValue))
        }
    }

    private func yourRankCard(_ standing: LeaderboardStanding) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your rank")
                    .appCaptionText()
                Text("#\(standing.rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.brandGreen)
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
        .background(AppColors.brandGreen.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private func leaderboardRow(_ standing: LeaderboardStanding) -> some View {
        HStack(spacing: 12) {
            Text("\(standing.rank)")
                .font(.headline)
                .foregroundStyle(standing.rank <= 3 ? AppColors.brandGreen : .secondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(standing.entry.displayName)
                    .font(.body)
                    .fontWeight(standing.isCurrentUser ? .semibold : .regular)
                Text("\(standing.entry.correctAnswers)/\(standing.entry.totalQuestions) correct")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(standing.entry.points)")
                .font(.headline)
                .foregroundStyle(AppColors.brandGreen)
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
