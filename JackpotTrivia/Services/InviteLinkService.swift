//
//  InviteLinkService.swift
//  JackpotTrivia
//
//  Local invite links (12h expiry, tiered referral limits).
//

import Foundation

enum InviteLinkError: Equatable, Error {
    case invalidOrExpired
    case atCapacity
    case referralLimitReached
    case invitesDisabled
    case pendingApproval
}

struct InviteLinkRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let token: String
    let createdAt: Date
    let expiresAt: Date
    let createdByMemberID: String?
    var redemptionCount: Int
    let maxRedemptions: Int

    var isExpired: Bool { Date() >= expiresAt }
}

struct AppMemberRecord: Codable, Equatable, Identifiable {
    let id: String
    let joinedAt: Date
    var referralsCreated: Int
    var role: MemberRole
    var invitedByMemberID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case joinedAt
        case referralsCreated
        case role
        case invitedByMemberID
    }

    init(
        id: String,
        joinedAt: Date,
        referralsCreated: Int,
        role: MemberRole,
        invitedByMemberID: String?
    ) {
        self.id = id
        self.joinedAt = joinedAt
        self.referralsCreated = referralsCreated
        self.role = role
        self.invitedByMemberID = invitedByMemberID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        referralsCreated = try container.decode(Int.self, forKey: .referralsCreated)
        role = try container.decodeIfPresent(MemberRole.self, forKey: .role) ?? .member
        invitedByMemberID = try container.decodeIfPresent(String.self, forKey: .invitedByMemberID)
    }

    var remainingReferrals: Int {
        max(0, role.maxReferrals - referralsCreated)
    }

    var canCreateInvites: Bool {
        remainingReferrals > 0 || role == .founder
    }
}

enum InviteLinkService {
    private static let invitesKey = "jackpotTrivia.inviteLinks"
    private static let membersKey = "jackpotTrivia.members"
    private static let currentMemberKey = "jackpotTrivia.currentMemberId"

    static let inviteURLScheme = "jackpottrivia"
    static let inviteLifetimeSeconds: TimeInterval = 72 * 60 * 60

    // MARK: - Current member

    static var currentMemberID: String? {
        get { UserDefaults.standard.string(forKey: currentMemberKey) }
        set { UserDefaults.standard.set(newValue, forKey: currentMemberKey) }
    }

    static var currentMember: AppMemberRecord? {
        guard let id = currentMemberID else { return nil }
        return members.first(where: { $0.id == id })
    }

    // MARK: - Invites

    static func createInvite(createdByMemberID: String? = nil) -> Result<InviteLinkRecord, InviteLinkError> {
        if let memberID = createdByMemberID {
            guard let member = members.first(where: { $0.id == memberID }) else {
                return .failure(.invalidOrExpired)
            }
            if member.remainingReferrals <= 0 {
                return .failure(.referralLimitReached)
            }
            var updated = members
            if let index = updated.firstIndex(where: { $0.id == memberID }) {
                updated[index].referralsCreated += 1
                members = updated
            }
        }

        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).uppercased()
        let now = Date()
        let record = InviteLinkRecord(
            id: UUID(),
            token: String(token),
            createdAt: now,
            expiresAt: now.addingTimeInterval(inviteLifetimeSeconds),
            createdByMemberID: createdByMemberID,
            redemptionCount: 0,
            maxRedemptions: 1
        )
        var list = invites
        list.append(record)
        invites = list
        return .success(record)
    }

    static func privateInviteURL(for token: String) -> URL? {
        URL(string: "\(inviteURLScheme)://invite?token=\(token)")
    }

    static func parseToken(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("\(inviteURLScheme)://"),
           let url = URL(string: trimmed),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
            return token.uppercased()
        }
        if trimmed.count >= AppConfig.minimumInviteCodeLength {
            return trimmed.uppercased()
        }
        return nil
    }

    static func grantOpenAccess() -> Result<AppMemberRecord, InviteLinkError> {
        if let memberID = currentMemberID,
           let existing = members.first(where: { $0.id == memberID }) {
            return .success(existing)
        }
        return finishJoinAfterValidation(invitedBy: nil, inviterRole: nil, usedFounderCode: false)
    }

    static func redeemInvite(raw: String) -> Result<AppMemberRecord, InviteLinkError> {
        if AccessControl.isOpenAccess {
            return grantOpenAccess()
        }

        guard AccessControl.allowInviteCodes else { return .failure(.invitesDisabled) }

        if let maxMembers = AccessControl.maxMembers, members.count >= maxMembers {
            return .failure(.atCapacity)
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.invalidOrExpired) }

        guard let token = parseToken(from: trimmed) else {
            return .failure(.invalidOrExpired)
        }

        var inviterID: String?
        var inviterRole: MemberRole?
        var valid = false

        if var link = invites.first(where: { $0.token == token }) {
            if link.isExpired { return .failure(.invalidOrExpired) }
            if link.redemptionCount >= link.maxRedemptions { return .failure(.invalidOrExpired) }
            link.redemptionCount += 1
            replaceInvite(link)
            valid = true
            inviterID = link.createdByMemberID
            if let inviterID, let inviter = members.first(where: { $0.id == inviterID }) {
                inviterRole = inviter.role
            }
        } else if AccessControl.isInviteCodeValid(token) {
            valid = true
            let normalized = AccessControl.normalizeInviteCode(token)
            let isFounderCode = AppConfig.founderInviteCodes.map {
                AccessControl.normalizeInviteCode($0)
            }.contains(normalized)
            if isFounderCode {
                return finishJoinAfterValidation(invitedBy: nil, inviterRole: nil, usedFounderCode: true)
            }
        }

        guard valid else { return .failure(.invalidOrExpired) }

        if AccessControl.requireManualApproval, !PendingInviteStore.isInstallationApproved() {
            PendingInviteStore.submit(rawInvite: trimmed)
            return .failure(.pendingApproval)
        }

        return finishJoinAfterValidation(
            invitedBy: inviterID,
            inviterRole: inviterRole,
            usedFounderCode: false
        )
    }

    private static func finishJoinAfterValidation(
        invitedBy: String?,
        inviterRole: MemberRole?,
        usedFounderCode: Bool
    ) -> Result<AppMemberRecord, InviteLinkError> {
        if let maxMembers = AccessControl.maxMembers, members.count >= maxMembers {
            return .failure(.atCapacity)
        }
        if let memberID = currentMemberID,
           let existing = members.first(where: { $0.id == memberID }) {
            return .success(existing)
        }

        let role: MemberRole
        if usedFounderCode {
            role = .founder
        } else if let inviterRole {
            role = inviterRole.roleForInvitee
        } else {
            role = .member
        }

        return registerMember(role: role, invitedBy: invitedBy)
    }

    static func registerMember(
        role: MemberRole = .member,
        invitedBy: String? = nil
    ) -> Result<AppMemberRecord, InviteLinkError> {
        if let maxMembers = AccessControl.maxMembers, members.count >= maxMembers {
            return .failure(.atCapacity)
        }
        let member = AppMemberRecord(
            id: UUID().uuidString,
            joinedAt: Date(),
            referralsCreated: 0,
            role: role,
            invitedByMemberID: invitedBy
        )
        var list = members
        list.append(member)
        members = list
        currentMemberID = member.id
        AccessControl.syncMemberCountFromInviteService()
        PrivateAccessStore.grantAccess()
        return .success(member)
    }

    static var remainingReferralsForCurrentMember: Int {
        currentMember?.remainingReferrals ?? 0
    }

    /// Promote a member to founder (admin tool).
    static func promoteToFounder(memberID: String) {
        var list = members
        guard let index = list.firstIndex(where: { $0.id == memberID }) else { return }
        list[index].role = .founder
        members = list
    }

    // MARK: - Persistence

    static var invites: [InviteLinkRecord] {
        get { load(key: invitesKey, default: []) }
        set { save(key: invitesKey, value: newValue) }
    }

    static var members: [AppMemberRecord] {
        get { load(key: membersKey, default: []) }
        set { save(key: membersKey, value: newValue) }
    }

    private static func replaceInvite(_ record: InviteLinkRecord) {
        var list = invites
        if let index = list.firstIndex(where: { $0.id == record.id }) {
            list[index] = record
            invites = list
        }
    }

    private static func load<T: Decodable>(key: String, default defaultValue: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return defaultValue
        }
        return decoded
    }

    private static func save<T: Encodable>(key: String, value: T) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func resetForTesting() {
        invites = []
        members = []
        currentMemberID = nil
        AccessControl.syncMemberCountFromInviteService()
    }
}
