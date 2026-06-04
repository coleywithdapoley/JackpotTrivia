//
//  MembershipServiceTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class MembershipServiceTests: XCTestCase {
    private let userID = "test-user-membership"

    override func setUp() {
        LocalMembershipService.resetForTesting()
    }

    func testValidCodeUpgradesToMember() throws {
        _ = MembershipAdminService.createCode(code: "GOLOUNGE", maxUses: 2)
        XCTAssertEqual(LocalMembershipService.shared.currentTier(for: userID), .free)

        let tier = try LocalMembershipService.shared.redeem(code: "GOLOUNGE", for: userID)
        XCTAssertEqual(tier, .member)
        XCTAssertEqual(LocalMembershipService.shared.currentTier(for: userID), .member)
    }

    func testExpiredMembershipCodeRejected() {
        _ = MembershipAdminService.createCode(code: "EXPIRED", expiresAt: Date().addingTimeInterval(-30))
        XCTAssertThrowsError(try LocalMembershipService.shared.redeem(code: "EXPIRED", for: userID))
    }

    func testMembershipIndependentFromAppAccess() throws {
        _ = MembershipAdminService.createCode(code: "MEMONLY")
        try LocalMembershipService.shared.redeem(code: "MEMONLY", for: userID)

        LocalAppAccessService.resetForTesting()
        if AppConfig.requireAppAccessCode {
            XCTAssertFalse(LocalAppAccessService.shared.hasAppAccess)
        }
        XCTAssertEqual(LocalMembershipService.shared.currentTier(for: userID), .member)
    }
}
