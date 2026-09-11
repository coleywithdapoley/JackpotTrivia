//
//  InviteAccessView.swift
//  JackpotTrivia
//

import SwiftUI

struct InviteAccessView: View {
    var onAccessGranted: () -> Void = {}

    @Environment(\.analytics) private var analytics

    @State private var inviteCode = ""
    @State private var inviteStatus: InviteStatus?
    @State private var readyToProceed = false
    @State private var accessRules = AccessControlSnapshot.current

    private var trimmedInviteCode: String {
        inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isOpenAccess: Bool {
        accessRules.isOpenAccess
    }

    private var showsInviteField: Bool {
        !isOpenAccess && accessRules.allowInviteCodes
    }

    private var isContinueEnabled: Bool {
        if isOpenAccess { return true }
        if !accessRules.allowInviteCodes { return false }
        return !trimmedInviteCode.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, AppSpacing.heroTop)

                formSection
                    .padding(.top, AppSpacing.section + AppSpacing.labelToField)

                Spacer(minLength: AppSpacing.sectionLarge)
            }
            .appScreenHorizontalPadding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .brandScreenBackground()
        .safeAreaInset(edge: .bottom) {
            footerNote
                .appScreenHorizontalPadding()
                .padding(.bottom, AppSpacing.screenBottom)
                .frame(maxWidth: .infinity)
                .background(AppColors.brandBackground)
        }
        .onAppear {
            refreshAccessRules()
            tryAutoContinueIfApproved()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Image(systemName: "trophy.fill")
                .font(.largeTitle)
                .foregroundStyle(AppColors.brandPrimary)
                .accessibilityHidden(true)

            Text(AppConfig.appDisplayName)
                .appScreenTitle()

            Text(isOpenAccess
                ? "Welcome! This beta is open to testers — tap Continue to play."
                : "An invite-only trivia experience. Enter your code or private link to join.")
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
            if showsInviteField {
                Text("Private invite link or code")
                    .appFieldLabel()

                TextField(AppConfig.Copy.invitePlaceholder, text: $inviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textContentType(.oneTimeCode)
                    .padding(.horizontal, AppSpacing.cardInnerHorizontal)
                    .padding(.vertical, 14)
                    .frame(minHeight: AppMetrics.minimumTouchTarget)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                            .strokeBorder(AppColors.cardBorder, lineWidth: 1)
                    )
                    .accessibilityLabel(AppConfig.Copy.inviteFieldLabel)
                    .accessibilityHint("Enter the code or link you received to join")
                    .onChange(of: inviteCode) { _, _ in
                        resetTransientState()
                    }
            } else if !isOpenAccess {
                Label(AppConfig.Copy.inviteDisabledMessage, systemImage: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            statusText
                .padding(.top, 4)
                .animation(AppAnimation.quick, value: inviteStatus)

            Button(action: continueTapped) {
                Text(isOpenAccess ? "Continue" : "Continue")
            }
            .buttonStyle(.appPrimary)
            .disabled(!isContinueEnabled)
            .accessibilityLabel("Continue")
            .accessibilityHint(continueAccessibilityHint)
            .padding(.top, AppSpacing.fieldToAction)
        }
    }

    private var continueAccessibilityHint: String {
        if isOpenAccess { return "Join the beta and start playing" }
        if !accessRules.allowInviteCodes { return "Invites are disabled" }
        return isContinueEnabled
            ? "Validates your invite and continues"
            : "Enter an invite code to continue"
    }

    @ViewBuilder
    private var statusText: some View {
        if let inviteStatus {
            statusMessage(for: inviteStatus)
                .font(.footnote)
                .foregroundStyle(statusColor(for: inviteStatus))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(statusAccessibilityLabel(for: inviteStatus))
        } else {
            Text(" ")
                .font(.footnote)
                .accessibilityHidden(true)
        }
    }

    private func statusColor(for status: InviteStatus) -> Color {
        switch status {
        case .pendingApproval:
            return AppColors.brandSecondary
        case .approved:
            return AppColors.brandPrimary
        default:
            return readyToProceed ? AppColors.brandPrimary : AppColors.error
        }
    }

    @ViewBuilder
    private func statusMessage(for status: InviteStatus) -> some View {
        switch status {
        case .empty:
            Text(AppConfig.Copy.inviteEmptyMessage)
        case .tooShort:
            Text(AppConfig.Copy.inviteTooShortMessage)
        case .invalid:
            Text(AppConfig.Copy.inviteInvalidMessage)
        case .disabled:
            Text(AppConfig.Copy.inviteDisabledMessage)
        case .atCapacity:
            Text("This app has reached its member limit. Contact the admin.")
        case .pendingApproval:
            Text("Request sent! An admin must approve your device before you can play. Check back after approval.")
        case .approved:
            Text("You're approved — tap Continue again.")
        }
    }

    private func statusAccessibilityLabel(for status: InviteStatus) -> String {
        switch status {
        case .empty: return "Error: \(AppConfig.Copy.inviteEmptyMessage)"
        case .tooShort: return "Error: \(AppConfig.Copy.inviteTooShortMessage)"
        case .invalid: return "Error: \(AppConfig.Copy.inviteInvalidMessage)"
        case .disabled: return "Error: \(AppConfig.Copy.inviteDisabledMessage)"
        case .atCapacity: return "Error: Member limit reached"
        case .pendingApproval: return "Pending admin approval"
        case .approved: return "Approved; tap Continue"
        }
    }

    private var footerNote: some View {
        VStack(spacing: 4) {
            if showsInviteField {
                Text("Invites expire after 12 hours. Each member may invite up to 2 others.")
                    .appCaptionText()
            }
            Text(AppConfig.Copy.inviteFooterNote)
                .appCaptionText()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func continueTapped() {
        refreshAccessRules()

        if isOpenAccess {
            completeOpenAccess()
            return
        }

        guard accessRules.allowInviteCodes else {
            inviteStatus = .disabled
            Haptics.error()
            return
        }

        let raw = trimmedInviteCode
        let codeLength = raw.count

        if raw.isEmpty {
            readyToProceed = false
            inviteStatus = .empty
            analytics.track(.inviteValidated(codeLength: 0, result: .empty))
            Haptics.error()
            return
        }

        if raw.count < AppConfig.minimumInviteCodeLength,
           !raw.lowercased().contains(InviteLinkService.inviteURLScheme) {
            readyToProceed = false
            inviteStatus = .tooShort
            analytics.track(.inviteValidated(codeLength: codeLength, result: .tooShort))
            Haptics.error()
            return
        }

        redeem(raw: raw, codeLength: codeLength)
    }

    private func completeOpenAccess() {
        switch InviteLinkService.grantOpenAccess() {
        case .success:
            analytics.track(.inviteValidated(codeLength: 0, result: .success))
            grantAccess()
        case .failure(.atCapacity):
            inviteStatus = .atCapacity
            analytics.track(.inviteValidated(codeLength: 0, result: .atCapacity))
            Haptics.error()
        default:
            inviteStatus = .invalid
            Haptics.error()
        }
    }

    private func redeem(raw: String, codeLength: Int) {
        switch InviteLinkService.redeemInvite(raw: raw) {
        case .success:
            analytics.track(.inviteValidated(codeLength: codeLength, result: .success))
            grantAccess()
        case .failure(.invalidOrExpired):
            readyToProceed = false
            inviteStatus = .invalid
            analytics.track(.inviteValidated(codeLength: codeLength, result: .invalidCode))
            Haptics.error()
        case .failure(.atCapacity):
            readyToProceed = false
            inviteStatus = .atCapacity
            analytics.track(.inviteValidated(codeLength: codeLength, result: .atCapacity))
            Haptics.error()
        case .failure(.invitesDisabled):
            readyToProceed = false
            inviteStatus = .disabled
            analytics.track(.inviteValidated(codeLength: codeLength, result: .invitesDisabled))
            Haptics.error()
        case .failure(.pendingApproval):
            readyToProceed = false
            inviteStatus = .pendingApproval
            analytics.track(.inviteValidated(codeLength: codeLength, result: .invalidCode))
            Haptics.warning()
        case .failure(.referralLimitReached):
            readyToProceed = false
            inviteStatus = .invalid
            Haptics.error()
        }
    }

    private func grantAccess() {
        readyToProceed = true
        inviteStatus = nil
        Haptics.success()
        onAccessGranted()
    }

    private func resetTransientState() {
        if readyToProceed { readyToProceed = false }
        if inviteStatus != nil { inviteStatus = nil }
    }

    private func refreshAccessRules() {
        AccessControl.syncMemberCountFromInviteService()
        accessRules = AccessControlSnapshot.current
    }

    private func tryAutoContinueIfApproved() {
        guard accessRules.requireManualApproval,
              PendingInviteStore.isInstallationApproved(),
              InviteLinkService.currentMemberID == nil else { return }
        inviteStatus = .approved
    }
}

// MARK: - Access snapshot for SwiftUI updates

private struct AccessControlSnapshot: Equatable {
    let isOpenAccess: Bool
    let allowInviteCodes: Bool
    let requireManualApproval: Bool

    static var current: AccessControlSnapshot {
        AccessControlSnapshot(
            isOpenAccess: AccessControl.isOpenAccess,
            allowInviteCodes: AccessControl.allowInviteCodes,
            requireManualApproval: AccessControl.requireManualApproval
        )
    }
}

// MARK: - Invite validation status

private enum InviteStatus: Equatable {
    case empty
    case tooShort
    case invalid
    case disabled
    case atCapacity
    case pendingApproval
    case approved
}

#Preview {
    InviteAccessView()
}
