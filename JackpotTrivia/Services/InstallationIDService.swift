//
//  InstallationIDService.swift
//  JackpotTrivia
//
//  Stable per-install ID for local invite approval (TestFlight / beta).
//

import Foundation

enum InstallationIDService {
    private static let key = "jackpotTrivia.installation.id"

    static var id: String {
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
