//
//  SupabaseConfig.swift
//  JackpotTrivia
//

import Foundation

enum SupabaseConfig {
    static let secretsFileName = "SupabaseSecrets"

    static var projectURL: URL? {
        guard let raw = string(forKey: "SUPABASE_URL")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw) else {
            return nil
        }
        return url
    }

    static var anonKey: String? {
        guard let key = string(forKey: "SUPABASE_ANON_KEY")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            return nil
        }
        return key
    }

    static var isConfigured: Bool {
        projectURL != nil && anonKey != nil
    }

    static var statusDescription: String {
        if isConfigured, let host = projectURL?.host {
            return "Connected (\(host))"
        }
        return "Offline — add SupabaseSecrets.plist (see docs/supabase/PHASE3_SETUP.md)"
    }

    private static func string(forKey key: String) -> String? {
        if let fromSecrets = secretsPlist?[key] as? String, !fromSecrets.isEmpty {
            return fromSecrets
        }
        if let fromBundle = Bundle.main.object(forInfoDictionaryKey: key) as? String, !fromBundle.isEmpty {
            return fromBundle
        }
        return ProcessInfo.processInfo.environment[key]
    }

    private static let secretsPlist: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return plist
    }()
}
