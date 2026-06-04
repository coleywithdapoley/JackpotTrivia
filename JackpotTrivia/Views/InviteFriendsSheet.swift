//
//  InviteFriendsSheet.swift
//  JackpotTrivia
//

import SwiftUI

struct InviteFriendsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var createdURL: String?
    @State private var errorMessage: String?

    private var slotsLeft: Int {
        InviteLinkService.remainingReferralsForCurrentMember
    }

    private var inviteQuotaDescription: String {
        "You have \(slotsLeft) invite\(slotsLeft == 1 ? "" : "s") to share. Each link expires in 72 hours."
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Text(inviteQuotaDescription)
                    .appBodyText()
                    .fixedSize(horizontal: false, vertical: true)

                Button("Create invite link") {
                    createLink()
                }
                .buttonStyle(.appPrimary)
                .disabled(slotsLeft == 0)

                if let createdURL {
                    Text(createdURL)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .appScreenHorizontalPadding()
            .padding(.top, AppSpacing.section)
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func createLink() {
        errorMessage = nil
        guard let memberID = InviteLinkService.currentMemberID else {
            errorMessage = "Join the app first before sending invites."
            return
        }
        switch InviteLinkService.createInvite(createdByMemberID: memberID) {
        case .success(let record):
            createdURL = InviteLinkService.privateInviteURL(for: record.token)?.absoluteString ?? record.token
        case .failure(.referralLimitReached):
            errorMessage = "You've used your 2 invites."
        case .failure:
            errorMessage = "Could not create invite."
        }
    }
}
