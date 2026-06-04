//
//  AdminAccessSettingsView.swift
//  JackpotTrivia
//

import SwiftUI

// MARK: - Model

extension AccessMode: Identifiable {
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inviteOnly:
            return "Invite Only"
        case .openNotListed:
            return "Open (Not Listed)"
        }
    }
}

struct AdminAccessSettings {
    var accessMode: AccessMode = AccessControl.accessMode
    var maxMembers: Int? = AccessControl.maxMembers
    var requireManualApproval: Bool = false
    var allowInviteCodes: Bool = AccessControl.allowInviteCodes
}

// MARK: - View

struct AdminAccessSettingsView: View {
    @Environment(\.analytics) private var analytics
    @Environment(\.featureGates) private var featureGates

    @State private var settings = AdminAccessSettings()
    @State private var isJoinLimitEnabled = false
    @State private var lastCreatedInviteURL: String?
    @State private var inviteErrorMessage: String?
    @State private var showPremiumPreview = false

    var body: some View {
        NavigationStack {
            List {
                backendSection
                appAccessSection
                membershipCodesSection
                questionCatalogSection
                monetizationSection
                inviteLinksSection
                accessModeSection
                joinLimitSection
                approvalAndInvitesSection
                pendingApprovalsSection
                infoSection
            }
            .navigationTitle("Access Settings")
            .navigationBarTitleDisplayMode(.large)
            .tint(AppColors.royalBlue)
            .onAppear {
                settings.accessMode = AccessControl.accessMode
                settings.maxMembers = AccessControl.maxMembers
                settings.allowInviteCodes = AccessControl.allowInviteCodes
                settings.requireManualApproval = AccessControl.requireManualApproval
                syncJoinLimitToggleFromSettings()
                AccessControl.syncMemberCountFromInviteService()
            }
            .premiumUpgradeSheet(isPresented: $showPremiumPreview)
        }
    }

    // MARK: - Sections

    private var backendSection: some View {
        Section {
            LabeledContent("Supabase", value: SupabaseConfig.isConfigured ? "Configured" : "Not configured")
            Text(SupabaseConfig.statusDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if SupabaseConfig.isConfigured {
                LabeledContent("Question pool", value: QuestionRepository.shared.poolSource.rawValue)
                LabeledContent("Remote questions", value: "\(QuestionRepository.shared.remoteQuestions.count)")
                if let error = QuestionRepository.shared.lastRefreshError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Backend (Phase 3)")
        } footer: {
            Text("Copy SupabaseSecrets.example.plist → SupabaseSecrets.plist and add your project URL + anon key. See docs/supabase/PHASE3_SETUP.md.")
        }
    }

    private var questionCatalogSection: some View {
        Section {
            let stats = QuestionCatalogLoader.catalogStats
            LabeledContent("Catalog version", value: stats.version > 0 ? "\(stats.version)" : "—")
            LabeledContent("Questions loaded", value: "\(stats.count)")
            LabeledContent("Approved in JSON", value: "\(stats.approved)")
            LabeledContent("Categories", value: "\(stats.categories)")
            LabeledContent("Playable pool", value: "\(QuestionBank.allQuestions.count)")
            LabeledContent("Unreviewed reports", value: "\(QuestionReportStore.unreviewedReports().count)")

            NavigationLink {
                QuestionReviewView()
            } label: {
                Text("Open question review")
            }

            NavigationLink {
                AddQuestionView()
            } label: {
                Text("Add a question on this device")
            }

            LabeledContent("Custom questions saved", value: "\(QuestionCatalogStore.count())")

            if !PrivateAccessStore.hasPrivateLoungeAccess {
                Button("Unlock Private Lounge on this device") {
                    PrivateAccessStore.grantAccess()
                }
            }
        } header: {
            Text("Question Catalog")
        } footer: {
            Text("Add questions here for you and Kwan — they merge with QuestionCatalog.json. Founders use tier-1 codes (see AppConfig.founderInviteCodes).")
        }
    }

    private var monetizationSection: some View {
        Section {
            LabeledContent("Access tier", value: featureGates.tierDisplayName)
            Text(featureGates.limitsSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if featureGates.showsAds {
                Label("Ad placeholders enabled for free tier", systemImage: "rectangle.on.rectangle.angled")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if PremiumAccessStore.isMockUnlocked {
                Label("Demo premium unlocked on this device", systemImage: "crown.fill")
                    .font(.footnote)
                    .foregroundStyle(AppColors.royalBlue)
                Button("Reset demo premium", role: .destructive) {
                    PremiumAccessStore.isMockUnlocked = false
                }
            }
            Button("Preview Premium upgrade screen") {
                showPremiumPreview = true
            }
        } header: {
            Text("Monetization Preview")
        } footer: {
            Text("Tier comes from AppConfig.defaultAccessTier until StoreKit entitlements are wired. Change that value to preview free vs premium limits.")
        }
    }

    private var inviteLinksSection: some View {
        Section {
            LabeledContent("Members joined", value: "\(InviteLinkService.members.count)")
            if let member = InviteLinkService.currentMember {
                LabeledContent("Your tier", value: member.role.displayName)
            }
            LabeledContent("Your referral slots left", value: "\(InviteLinkService.remainingReferralsForCurrentMember)")

            Button("Create private invite link (72h)") {
                createAdminInvite()
            }

            if let lastCreatedInviteURL {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Latest link (copy & share)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lastCreatedInviteURL)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }

            if let inviteErrorMessage {
                Text(inviteErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Private Invites")
        } footer: {
            Text("Links expire after 72 hours. You have a limited number of invites to share.")
        }
    }

    private var appAccessSection: some View {
        Section {
            LabeledContent("App access gate", value: AppConfig.requireAppAccessCode ? "On" : "Off")
            LabeledContent("Device has access", value: LocalAppAccessService.shared.hasAppAccess ? "Yes" : "No")
            LabeledContent("Active codes", value: "\(AppAccessAdminService.listAccessCodes().filter(\.isActive).count)")

            Button("Create app access code TESTACCESS") {
                _ = AppAccessAdminService.createAccessCode(code: "TESTACCESS", maxUses: 10)
            }
        } header: {
            Text("App Access Codes")
        } footer: {
            Text("When requireAppAccessCode is true in AppConfig, users need a code before sign-in. Default seeds: JOIN2026, BETA2026.")
        }
    }

    private var membershipCodesSection: some View {
        Section {
            LabeledContent("Active lounge codes", value: "\(MembershipAdminService.listCodes().filter(\.isActive).count)")

            Button("Create lounge code TESTLOUNGE") {
                _ = MembershipAdminService.createCode(code: "TESTLOUNGE", maxUses: 10)
            }
        } header: {
            Text("Lounge / Membership Codes")
        } footer: {
            Text("Redeem on the Membership screen. Default seeds: LOUNGE2026, MEMBER2026.")
        }
    }

    private var accessModeSection: some View {
        Section {
            Picker("Access Mode", selection: $settings.accessMode) {
                ForEach(AccessMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .frame(minHeight: AppMetrics.minimumTouchTarget)
            .accessibilityLabel("Access mode")
            .accessibilityHint("Choose how users can join the app")
            .onChange(of: settings.accessMode) { _, _ in
                persistAccessSettings()
                trackAdminSettingsChanged()
            }
        } header: {
            Text("Access Mode")
        } footer: {
            Text(accessModeFooterText)
        }
    }

    private var joinLimitSection: some View {
        Section {
            Toggle("Limit number of members", isOn: $isJoinLimitEnabled)
                .accessibilityHint(
                    isJoinLimitEnabled
                        ? "Double tap to turn off the member limit"
                        : "Double tap to cap how many members can join"
                )
                .onChange(of: isJoinLimitEnabled) { _, enabled in
                    if enabled {
                        if settings.maxMembers == nil {
                            settings.maxMembers = AppConfig.defaultMemberLimitWhenEnabled
                        }
                    } else {
                        settings.maxMembers = nil
                    }
                    persistAccessSettings()
                    trackAdminSettingsChanged()
                }

            if isJoinLimitEnabled {
                Stepper(
                    value: Binding(
                        get: { settings.maxMembers ?? AppConfig.defaultMemberLimitWhenEnabled },
                        set: {
                            settings.maxMembers = $0
                            persistAccessSettings()
                            trackAdminSettingsChanged()
                        }
                    ),
                    in: 1...10_000,
                    step: 1
                ) {
                    HStack {
                        Text("Maximum members")
                        Spacer()
                        Text("\(settings.maxMembers ?? AppConfig.defaultMemberLimitWhenEnabled)")
                            .foregroundStyle(AppColors.royalBlue)
                            .fontWeight(.semibold)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Maximum members, \(settings.maxMembers ?? AppConfig.defaultMemberLimitWhenEnabled)"
                )
                .accessibilityHint("Adjust the maximum number of members allowed to join")
            }
        } header: {
            Text("Join Limit")
        } footer: {
            Text(isJoinLimitEnabled
                ? "New members cannot join once this limit is reached."
                : "No member cap is applied.")
        }
    }

    private var approvalAndInvitesSection: some View {
        Section {
            Toggle("Require manual approval", isOn: $settings.requireManualApproval)
                .accessibilityHint("When on, new members must be approved before joining")
                .onChange(of: settings.requireManualApproval) { _, _ in
                    persistAccessSettings()
                    trackAdminSettingsChanged()
                }

            Toggle("Allow invite codes", isOn: $settings.allowInviteCodes)
                .accessibilityHint(
                    settings.allowInviteCodes
                        ? "Double tap to disable invite codes on the join screen"
                        : "Double tap to allow users to join with invite codes"
                )
                .onChange(of: settings.allowInviteCodes) { _, _ in
                    persistAccessSettings()
                    trackAdminSettingsChanged()
                }
        } header: {
            Text("Approval & Invites")
        } footer: {
            Text("Control whether new members need admin approval and whether invite codes can be used to join.")
        }
    }

    private var pendingApprovalsSection: some View {
        Section {
            let pending = PendingInviteStore.allPending()
            LabeledContent("Pending requests", value: "\(pending.count)")

            if pending.isEmpty {
                Text("No devices waiting for approval.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(pending) { request in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(request.rawInvite)
                            .font(.footnote)
                            .lineLimit(2)
                        Text(request.requestedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Approve") {
                                PendingInviteStore.approve(installationID: request.installationID)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.royalBlue)

                            Button("Reject", role: .destructive) {
                                PendingInviteStore.reject(installationID: request.installationID)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button("Approve all pending") {
                    PendingInviteStore.approveAllPending()
                }
            }
        } header: {
            Text("Pending join requests")
        } footer: {
            Text("Shown when manual approval is on. Testers must tap Continue again after you approve their device.")
        }
    }

    private var infoSection: some View {
        Section {
            Label {
                Text("Access settings persist on this device. Member cap and invite rules apply immediately. Cloud sync requires Supabase later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.royalBlue)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
        } header: {
            Text("Info")
        }
    }

    // MARK: - Helpers

    private var accessModeFooterText: String {
        switch settings.accessMode {
        case .inviteOnly:
            return "Only users with a valid invite code can join."
        case .openNotListed:
            return "Anyone with the app link can join, but the app is not publicly listed."
        }
    }

    private func syncJoinLimitToggleFromSettings() {
        isJoinLimitEnabled = settings.maxMembers != nil
    }

    private func persistAccessSettings() {
        AccessControl.applyAdminSettings(
            accessMode: settings.accessMode,
            maxMembers: settings.maxMembers,
            allowInviteCodes: settings.allowInviteCodes,
            requireManualApproval: settings.requireManualApproval
        )
    }

    private func trackAdminSettingsChanged() {
        analytics.track(.adminSettingsChanged(
            accessMode: settings.accessMode.rawValue,
            maxMembers: settings.maxMembers,
            requireApproval: settings.requireManualApproval
        ))
    }

    private func createAdminInvite() {
        inviteErrorMessage = nil
        switch InviteLinkService.createInvite(createdByMemberID: InviteLinkService.currentMemberID) {
        case .success(let record):
            if let url = InviteLinkService.privateInviteURL(for: record.token) {
                lastCreatedInviteURL = url.absoluteString
            } else {
                lastCreatedInviteURL = record.token
            }
        case .failure(.referralLimitReached):
            inviteErrorMessage = "Referral limit reached (2 invites per member)."
        case .failure(.atCapacity):
            inviteErrorMessage = "Member cap reached."
        case .failure:
            inviteErrorMessage = "Could not create invite."
        }
    }
}

#Preview {
    AdminAccessSettingsView()
}
