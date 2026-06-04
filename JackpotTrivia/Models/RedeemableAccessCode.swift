//
//  RedeemableAccessCode.swift
//  JackpotTrivia
//

import Foundation

struct RedeemableAccessCode: Codable, Equatable, Identifiable {
    let code: String
    var maxUses: Int?
    var usedCount: Int
    var expiresAt: Date?
    var isActive: Bool

    var id: String { code }

    init(
        code: String,
        maxUses: Int? = nil,
        usedCount: Int = 0,
        expiresAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.code = code
        self.maxUses = maxUses
        self.usedCount = usedCount
        self.expiresAt = expiresAt
        self.isActive = isActive
    }

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    func canRedeem(at date: Date = .now) -> Bool {
        guard isActive else { return false }
        if let expiresAt, date >= expiresAt { return false }
        if let maxUses, usedCount >= maxUses { return false }
        return true
    }
}

enum AccessCodeRedemptionError: Error, Equatable {
    case invalidOrExpired

    var userMessage: String {
        "Invalid or expired code."
    }
}

enum AccessCodeRedemption {
    static func validate(_ code: RedeemableAccessCode, at date: Date = .now) -> Result<Void, AccessCodeRedemptionError> {
        guard code.canRedeem(at: date) else {
            return .failure(.invalidOrExpired)
        }
        return .success(())
    }

    static func findCode(in codes: [RedeemableAccessCode], matching raw: String) -> RedeemableAccessCode? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return nil }
        return codes.first { $0.normalizedCode == normalized }
    }
}
