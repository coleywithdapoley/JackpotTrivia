//
//  ChallengeFriendSheet.swift
//  JackpotTrivia
//

import SwiftUI

struct ChallengeFriendSheet: View {
    @Environment(\.dismiss) private var dismiss

    let challenge: FriendChallenge
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Text("Challenge a friend")
                    .appScreenTitle()

                Text(challenge.message)
                    .appBodyText()
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Label("\(challenge.points) points", systemImage: "star.fill")
                    Label("\(challenge.accuracyPercent)% accuracy", systemImage: "target")
                    Label("Daily deck: \(challenge.dayKey)", systemImage: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(AppColors.brandGreen)

                ShareLink(item: ChallengeService.shareText(for: challenge)) {
                    Text("Share challenge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.appPrimary)

                Button("Done") { dismiss() }
                    .buttonStyle(.appSecondary)
            }
            .appScreenHorizontalPadding()
            .padding(.top, AppSpacing.section)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ChallengeFriendSheet(
        challenge: FriendChallenge(
            challengerName: "Alex",
            points: 1250,
            accuracyPercent: 80,
            dayKey: "2026-05-27",
            createdAt: .now
        )
    )
}
