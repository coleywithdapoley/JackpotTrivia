//
//  UserProfileStore.swift
//  JackpotTrivia
//
//  Local comfort preferences until per-account profiles sync from a backend.
//

import Foundation

enum UserProfileStore {
    private static let key = "jackpotTrivia.userContentProfile"

    static var profile: UserContentProfile {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(UserContentProfile.self, from: data) else {
                return .default
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}
