//
//  AppAccessService.swift
//  JackpotTrivia
//

import Foundation

protocol AppAccessServiceProtocol {
    var hasAppAccess: Bool { get }
    func redeemAccessCode(_ raw: String) throws
}

enum AppAccessAdminService {
    static func createAccessCode(
        code: String,
        maxUses: Int? = nil,
        expiresAt: Date? = nil
    ) -> RedeemableAccessCode {
        let record = RedeemableAccessCode(
            code: code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            maxUses: maxUses,
            expiresAt: expiresAt
        )
        LocalAppAccessService.shared.insertCode(record)
        return record
    }

    static func listAccessCodes() -> [RedeemableAccessCode] {
        LocalAppAccessService.shared.allCodes()
    }

    static func deactivateAccessCode(_ raw: String) {
        LocalAppAccessService.shared.setActive(false, for: raw)
    }
}

final class LocalAppAccessService: AppAccessServiceProtocol {
    static let shared = LocalAppAccessService()

    private let codesKey = "jackpotTrivia.appAccess.codes"
    private let grantedKey = "jackpotTrivia.appAccess.granted"

    #if DEBUG
    private static var forceGateEnabledForTesting = false

    static func setGateEnabledForTesting(_ enabled: Bool) {
        forceGateEnabledForTesting = enabled
    }
    #endif

    private var isAccessGateActive: Bool {
        #if DEBUG
        if Self.forceGateEnabledForTesting { return true }
        #endif
        return AppConfig.requireAppAccessCode
    }

    private init() {
        seedDefaultsIfNeeded()
    }

    var hasAppAccess: Bool {
        if !isAccessGateActive { return true }
        return UserDefaults.standard.bool(forKey: grantedKey)
    }

    func redeemAccessCode(_ raw: String) throws {
        guard isAccessGateActive else { return }
        var codes = loadCodes()
        guard let index = codes.firstIndex(where: { AccessCodeRedemption.findCode(in: [$0], matching: raw) != nil }) else {
            throw AccessCodeRedemptionError.invalidOrExpired
        }
        guard case .success = AccessCodeRedemption.validate(codes[index]) else {
            throw AccessCodeRedemptionError.invalidOrExpired
        }
        codes[index].usedCount += 1
        saveCodes(codes)
        UserDefaults.standard.set(true, forKey: grantedKey)
    }

    func allCodes() -> [RedeemableAccessCode] {
        loadCodes()
    }

    func insertCode(_ code: RedeemableAccessCode) {
        var codes = loadCodes()
        if let index = codes.firstIndex(where: { $0.normalizedCode == code.normalizedCode }) {
            codes[index] = code
        } else {
            codes.append(code)
        }
        saveCodes(codes)
    }

    func setActive(_ active: Bool, for raw: String) {
        var codes = loadCodes()
        guard let index = codes.firstIndex(where: { AccessCodeRedemption.findCode(in: [$0], matching: raw) != nil }) else {
            return
        }
        codes[index].isActive = active
        saveCodes(codes)
    }

    static func resetForTesting() {
        #if DEBUG
        forceGateEnabledForTesting = false
        #endif
        UserDefaults.standard.removeObject(forKey: shared.codesKey)
        UserDefaults.standard.removeObject(forKey: shared.grantedKey)
        shared.seedDefaultsIfNeeded()
    }

    private func seedDefaultsIfNeeded() {
        guard loadCodes().isEmpty else { return }
        saveCodes([
            RedeemableAccessCode(code: "JOIN2026", maxUses: 500),
            RedeemableAccessCode(code: "BETA2026", maxUses: nil),
        ])
    }

    private func loadCodes() -> [RedeemableAccessCode] {
        guard let data = UserDefaults.standard.data(forKey: codesKey),
              let decoded = try? JSONDecoder().decode([RedeemableAccessCode].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveCodes(_ codes: [RedeemableAccessCode]) {
        if let data = try? JSONEncoder().encode(codes) {
            UserDefaults.standard.set(data, forKey: codesKey)
        }
    }
}

/// Stub for future Supabase-backed access codes.
final class SupabaseAppAccessService: AppAccessServiceProtocol {
    var hasAppAccess: Bool { LocalAppAccessService.shared.hasAppAccess }

    func redeemAccessCode(_ raw: String) throws {
        try LocalAppAccessService.shared.redeemAccessCode(raw)
    }
}
