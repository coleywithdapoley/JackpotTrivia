//
//  MembershipView.swift
//  JackpotTrivia
//

import SwiftUI

struct MembershipView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.analytics) private var analytics

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false

    private var tier: MembershipTier {
        auth.currentUser?.membershipTier ?? .free
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Label("Membership", systemImage: tier.isMember ? "checkmark.seal.fill" : "person.crop.circle")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.brandGreen)

                LabeledContent("Current tier", value: tier.displayName)

                if tier.isMember {
                    memberSection
                } else {
                    freeSection
                }
            }
            .appScreenHorizontalPadding()
            .padding(.vertical, AppSpacing.section)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Membership")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            auth.refreshMembershipTier()
        }
    }

    private var memberSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("You're a Member!")
                .font(.headline)
                .foregroundStyle(AppColors.brandGreen)

            Text("Perks include access to the Private Lounge (18+ topics) and future member-only modes.")
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)

            if let member = InviteLinkService.currentMember, member.canCreateInvites {
                Text("You have \(member.remainingReferrals) invites to share.")
                    .appCaptionText()
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.brandGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private var freeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Membership is invite-only. Enter a lounge code from the admins to unlock extra perks.")
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
                Text(AppConfig.Copy.loungeCodeTitle)
                    .appFieldLabel()
                TextField("Enter lounge code", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let successMessage {
                Text(successMessage)
                    .font(.footnote)
                    .foregroundStyle(AppColors.brandGreen)
            }

            Button(action: unlockTapped) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Unlock")
                }
            }
            .buttonStyle(.appPrimary)
            .disabled(isLoading || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    private func unlockTapped() {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try auth.redeemMembershipCode(code)
            analytics.track(.membershipRedeemed(success: true))
            successMessage = "You're now a Member!"
            code = ""
            Haptics.success()
        } catch {
            analytics.track(.membershipRedeemed(success: false))
            errorMessage = AccessCodeRedemptionError.invalidOrExpired.userMessage
            Haptics.error()
        }
    }
}

#Preview {
    NavigationStack {
        MembershipView()
            .environmentObject(AuthManager.shared)
    }
}
