//
//  PendingChallengeBanner.swift
//  JackpotTrivia
//

import SwiftUI

struct PendingChallengeBanner: View {
    let challenge: FriendChallenge
    var onDismiss: () -> Void = {}
    var onAccept: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Label("Friend challenge", systemImage: "flag.checkered")
                .font(.headline)
                .foregroundStyle(AppColors.brandGreen)

            Text(challenge.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.stackItem) {
                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.appSecondary)

                Button("Beat their score", action: onAccept)
                    .buttonStyle(.appPrimary)
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }
}
