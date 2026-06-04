//
//  MembershipService.swift
//  JackpotTrivia
//

import Foundation

protocol MembershipServiceProtocol {
    func currentTier(for userID: String) -> MembershipTier
    func redeem(code: String, for userID: String) throws -> MembershipTier
}

enum MembershipAdminService {
    static func createCode(
        code: String,
        maxUses: Int? = nil,
        expiresAt: Date? = nil
    ) -> RedeemableAccessCode {
        let record = RedeemableAccessCode(
            code: code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            maxUses: maxUses,
            expiresAt: expiresAt
        )
        LocalMembershipService.shared.insertCode(record)
        return record
    }

    static func listCodes() -> [RedeemableAccessCode] {
        LocalMembershipService.shared.allCodes()
    }

    static func deactivate(code: String) {
        LocalMembershipService.shared.setActive(false, for: code)
    }
}

final class LocalMembershipService: MembershipServiceProtocol {
    static let shared = LocalMembershipService()

    private let codesKey = "jackpotTrivia.membership.codes"
    private let tierPrefix = "jackpotTrivia.membership.tier."

    private init() {
        seedDefaultsIfNeeded()
    }

    func currentTier(for userID: String) -> MembershipTier {
        guard let raw = UserDefaults.standard.string(forKey: tierKey(userID)),
              let tier = MembershipTier(rawValue: raw) else {
            return .free
        }
        return tier
    }

    @discardableResult
    func redeem(code: String, for userID: String) throws -> MembershipTier {
        var codes = loadCodes()
        guard let index = codes.firstIndex(where: { AccessCodeRedemption.findCode(in: [$0], matching: code) != nil }) else {
            throw AccessCodeRedemptionError.invalidOrExpired
        }
        guard case .success = AccessCodeRedemption.validate(codes[index]) else {
            throw AccessCodeRedemptionError.invalidOrExpired
        }
        codes[index].usedCount += 1
        saveCodes(codes)
        persistTier(.member, for: userID)
        return .member
    }

    func persistTier(_ tier: MembershipTier, for userID: String) {
        UserDefaults.standard.set(tier.rawValue, forKey: tierKey(userID))
        NotificationCenter.default.post(name: .membershipDidChange, object: nil)
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
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: shared.codesKey)
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(shared.tierPrefix) }
            .forEach { defaults.removeObject(forKey: $0) }
        shared.seedDefaultsIfNeeded()
    }

    private func tierKey(_ userID: String) -> String {
        tierPrefix + userID
    }

    private func seedDefaultsIfNeeded() {
        guard loadCodes().isEmpty else { return }
        saveCodes([
            RedeemableAccessCode(code: "LOUNGE2026", maxUses: 200),
            RedeemableAccessCode(code: "MEMBER2026", maxUses: nil),
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

extension Notification.Name {
    static let membershipDidChange = Notification.Name("membershipDidChange")
}
