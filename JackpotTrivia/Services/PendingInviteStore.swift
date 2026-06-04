//
//  PendingInviteStore.swift
//  JackpotTrivia
//
//  Local queue when admin enables manual approval before join.
//

import Foundation

struct PendingInviteRequest: Codable, Equatable, Identifiable {
    let id: String
    let installationID: String
    let rawInvite: String
    let requestedAt: Date
}

enum PendingInviteStore {
    private static let pendingKey = "jackpotTrivia.invite.pending"
    private static let approvedInstallationsKey = "jackpotTrivia.invite.approvedInstallations"

    static func submit(rawInvite: String) {
        let request = PendingInviteRequest(
            id: UUID().uuidString,
            installationID: InstallationIDService.id,
            rawInvite: rawInvite,
            requestedAt: .now
        )
        var list = allPending()
        list.removeAll { $0.installationID == request.installationID }
        list.append(request)
        savePending(list)
    }

    static func allPending() -> [PendingInviteRequest] {
        guard let data = UserDefaults.standard.data(forKey: pendingKey),
              let decoded = try? JSONDecoder().decode([PendingInviteRequest].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.requestedAt > $1.requestedAt }
    }

    static func isInstallationApproved() -> Bool {
        approvedInstallationIDs().contains(InstallationIDService.id)
    }

    static func approve(installationID: String) {
        var approved = approvedInstallationIDs()
        approved.insert(installationID)
        saveApproved(approved)
        var pending = allPending()
        pending.removeAll { $0.installationID == installationID }
        savePending(pending)
    }

    static func reject(installationID: String) {
        var pending = allPending()
        pending.removeAll { $0.installationID == installationID }
        savePending(pending)
    }

    static func approveAllPending() {
        let pending = allPending()
        var approved = approvedInstallationIDs()
        for request in pending {
            approved.insert(request.installationID)
        }
        saveApproved(approved)
        savePending([])
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: approvedInstallationsKey)
    }

    private static func approvedInstallationIDs() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: approvedInstallationsKey),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return decoded
    }

    private static func saveApproved(_ ids: Set<String>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: approvedInstallationsKey)
        }
    }

    private static func savePending(_ requests: [PendingInviteRequest]) {
        if let data = try? JSONEncoder().encode(requests) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }
}
