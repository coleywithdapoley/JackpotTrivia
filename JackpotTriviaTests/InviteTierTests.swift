//
//  InviteTierTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class InviteTierTests: XCTestCase {
    override func setUp() {
        super.setUp()
        InviteLinkService.resetForTesting()
        PrivateAccessStore.resetForTesting()
        AccessControl.resetToDefaults()
        AccessControl.allowInviteCodes = true
        AccessControl.accessMode = .inviteOnly
    }

    func testFounderCode_assignsFounderRole() {
        AccessControl.validInviteCodes = ["TRIVIA2026"]
        let result = InviteLinkService.redeemInvite(raw: "TRIVIA2026")
        guard case .success(let member) = result else {
            XCTFail("Expected success")
            return
        }
        XCTAssertEqual(member.role, .founder)
        XCTAssertTrue(PrivateAccessStore.hasPrivateLoungeAccess)
    }

    func testLeafMember_cannotCreateInvite() {
        let founder = AppMemberRecord(
            id: "f1",
            joinedAt: .now,
            referralsCreated: 0,
            role: .founder,
            invitedByMemberID: nil
        )
        InviteLinkService.members = [founder]
        _ = InviteLinkService.createInvite(createdByMemberID: "f1")

        guard let link = InviteLinkService.invites.first else {
            XCTFail("Missing invite")
            return
        }

        InviteLinkService.currentMemberID = nil
        _ = InviteLinkService.redeemInvite(raw: link.token)

        guard let tier2 = InviteLinkService.currentMember else {
            XCTFail("Missing tier2")
            return
        }
        XCTAssertEqual(tier2.role, .member)

        InviteLinkService.currentMemberID = tier2.id
        _ = InviteLinkService.createInvite(createdByMemberID: tier2.id)
        guard let leafLink = InviteLinkService.invites.last else {
            XCTFail("Missing leaf link")
            return
        }

        InviteLinkService.currentMemberID = nil
        _ = InviteLinkService.redeemInvite(raw: leafLink.token)
        guard let leaf = InviteLinkService.currentMember else {
            XCTFail("Missing leaf")
            return
        }
        XCTAssertEqual(leaf.role, .leaf)
        XCTAssertEqual(leaf.remainingReferrals, 0)

        InviteLinkService.currentMemberID = leaf.id
        let create = InviteLinkService.createInvite(createdByMemberID: leaf.id)
        XCTAssertEqual(create, .failure(.referralLimitReached))
    }
}
