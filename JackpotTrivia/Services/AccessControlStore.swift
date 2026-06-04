//
//  AccessControlStore.swift
//  JackpotTrivia
//
//  Persists admin access settings locally (no Supabase required).
//

import Foundation

enum AccessControlStore {
    private static let accessModeKey = "jackpotTrivia.access.mode"
    private static let maxMembersKey = "jackpotTrivia.access.maxMembers"
    private static let allowInviteCodesKey = "jackpotTrivia.access.allowInviteCodes"
    private static let requireManualApprovalKey = "jackpotTrivia.access.requireManualApproval"

    static func loadIntoAccessControl() {
        guard UserDefaults.standard.object(forKey: accessModeKey) != nil else {
            return
        }

        if let raw = UserDefaults.standard.string(forKey: accessModeKey),
           let mode = AccessMode(rawValue: raw) {
            AccessControl.accessMode = mode
        }

        if UserDefaults.standard.object(forKey: maxMembersKey) != nil {
            let value = UserDefaults.standard.integer(forKey: maxMembersKey)
            AccessControl.maxMembers = value > 0 ? value : nil
        }

        if UserDefaults.standard.object(forKey: allowInviteCodesKey) != nil {
            AccessControl.allowInviteCodes = UserDefaults.standard.bool(forKey: allowInviteCodesKey)
        }

        AccessControl.requireManualApproval = UserDefaults.standard.bool(forKey: requireManualApprovalKey)
        AccessControl.syncMemberCountFromInviteService()
    }

    static func persistFromAccessControl() {
        UserDefaults.standard.set(AccessControl.accessMode.rawValue, forKey: accessModeKey)
        if let maxMembers = AccessControl.maxMembers {
            UserDefaults.standard.set(maxMembers, forKey: maxMembersKey)
        } else {
            UserDefaults.standard.removeObject(forKey: maxMembersKey)
        }
        UserDefaults.standard.set(AccessControl.allowInviteCodes, forKey: allowInviteCodesKey)
        UserDefaults.standard.set(AccessControl.requireManualApproval, forKey: requireManualApprovalKey)
    }

    static func resetForTesting() {
        [
            accessModeKey,
            maxMembersKey,
            allowInviteCodesKey,
            requireManualApprovalKey,
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
