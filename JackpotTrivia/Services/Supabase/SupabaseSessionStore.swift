//
//  SupabaseSessionStore.swift
//  JackpotTrivia
//

import Foundation

struct SupabaseSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let userID: String
    let email: String
    var displayName: String?
    var expiresAt: Date?
}

enum SupabaseSessionStore {
    private static let key = "jackpotTrivia.supabase.session"

    static var current: SupabaseSession? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let session = try? JSONDecoder().decode(SupabaseSession.self, from: data) else {
            return nil
        }
        return session
    }

    static func save(_ session: SupabaseSession?) {
        guard let session else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
