//
//  AdminAccess.swift
//  JackpotTrivia
//
//  Admin is the seeded account in AppConfig (adminEmail / adminPassword).
//

import Foundation

enum AdminAccess {
    /// True when `email` is on the founder allowlist in `AppConfig.adminEmails`.
    static func isAdmin(
        email: String,
        allowlist: Set<String> = AppConfig.adminEmails
    ) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return false }
        return allowlist.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized }
    }
}
