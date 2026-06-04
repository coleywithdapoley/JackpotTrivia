//
//  AccessControl.swift
//  JackpotTrivia
//
//  Access rules. Defaults from AppConfig; admin changes persist via AccessControlStore.
//

import Foundation

enum AccessMode: String, CaseIterable, Equatable, Codable {
    case inviteOnly
    case openNotListed
}

enum AccessCheckResult: Equatable {
    case success
    case invalidCode
    case atCapacity
    case inviteNotRequired
    case invitesDisabled
    case pendingApproval
}

enum AccessControl {
    static var accessMode: AccessMode = .inviteOnly

    static var validInviteCodes: Set<String> = Set(
        AppConfig.defaultInviteCodes.map { normalizeInviteCode($0) }
    )

    static var maxMembers: Int? = AppConfig.defaultMaxMembers

    static var currentMemberCount: Int = 0

    static var allowInviteCodes: Bool = true

    /// When true, valid invites queue until admin approves this installation.
    static var requireManualApproval: Bool = false

    static var isOpenAccess: Bool {
        accessMode == .openNotListed
    }

    static func normalizeInviteCode(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func isInviteCodeValid(_ rawCode: String) -> Bool {
        guard allowInviteCodes else { return false }
        let code = normalizeInviteCode(rawCode)
        return validInviteCodes.contains(code)
    }

    /// Full invite check including access mode and capacity.
    static func validateInvite(code: String) -> AccessCheckResult {
        if accessMode == .openNotListed {
            return .inviteNotRequired
        }

        if let maxMembers, currentMemberCount >= maxMembers {
            return .atCapacity
        }

        guard allowInviteCodes else {
            return .invitesDisabled
        }

        if isInviteCodeValid(code) {
            if requireManualApproval, !PendingInviteStore.isInstallationApproved() {
                return .pendingApproval
            }
            return .success
        }

        return .invalidCode
    }

    static func syncMemberCountFromInviteService() {
        currentMemberCount = InviteLinkService.members.count
    }

    static func applyAdminSettings(
        accessMode: AccessMode,
        maxMembers: Int?,
        allowInviteCodes: Bool,
        requireManualApproval: Bool
    ) {
        self.accessMode = accessMode
        self.maxMembers = maxMembers
        self.allowInviteCodes = allowInviteCodes
        self.requireManualApproval = requireManualApproval
        syncMemberCountFromInviteService()
        AccessControlStore.persistFromAccessControl()
    }

    /// Reset to AppConfig defaults (e.g. after tests or admin reset).
    static func resetToDefaults() {
        accessMode = .inviteOnly
        validInviteCodes = Set(AppConfig.defaultInviteCodes.map { normalizeInviteCode($0) })
        maxMembers = AppConfig.defaultMaxMembers
        currentMemberCount = 0
        allowInviteCodes = true
        requireManualApproval = false
        AccessControlStore.persistFromAccessControl()
    }
}
