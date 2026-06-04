//
//  PrivateLoungeAccessView.swift
//  JackpotTrivia
//
//  Invite-only 18+ lounge (separate from public daily/practice).
//

import SwiftUI

struct PrivateLoungeAccessView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var gameSession: GameSession
    @Environment(\.analytics) private var analytics

    var onPlay: () -> Void = {}
    var onEnterLoungeCode: () -> Void = {}

    @State private var showAgeConfirm = false

    private var isMember: Bool {
        auth.currentUser?.membershipTier.isMember == true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Label("Private Lounge", systemImage: "lock.fill")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.brandGreen)

                Text("18+ topics for members. Cash prizes stay at live events — not in-app gambling.")
                    .appBodyText()
                    .fixedSize(horizontal: false, vertical: true)

                if isMember {
                    accessGrantedSection
                } else {
                    lockedSection
                }
            }
            .appScreenHorizontalPadding()
            .padding(.vertical, AppSpacing.section)
        }
        .background(
            CategoryTheme.backgroundGradient(for: "Private Lounge")
                .ignoresSafeArea()
        )
        .navigationTitle("Private Lounge")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            auth.refreshMembershipTier()
            if !isMember {
                analytics.track(.loungeAccessBlocked)
            }
        }
        .alert("18+ only", isPresented: $showAgeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("I'm 18 or older") {
                gameSessionBeginLounge()
            }
        } message: {
            Text("This section may include mature trivia. You must be 18 or older.")
        }
    }

    private func gameSessionBeginLounge() {
        gameSession.beginPrivateLoungeRound()
        onPlay()
    }

    private var accessGrantedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            if let member = InviteLinkService.currentMember, member.canCreateInvites {
                Text("You have \(member.remainingReferrals) invites to share.")
                    .appCaptionText()
            }

            Text("Mature questions only. Leaving the app during a timed question forfeits the round.")
                .appCaptionText()

            Button("Start lounge round") {
                showAgeConfirm = true
            }
            .buttonStyle(.appPrimary)
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text(AppConfig.Copy.loungeMembersOnly)
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)

            Button("Enter lounge code") {
                onEnterLoungeCode()
            }
            .buttonStyle(.appPrimary)
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.cardBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PrivateLoungeAccessView()
            .environmentObject(AuthManager.shared)
            .environmentObject(GameSession())
    }
}
