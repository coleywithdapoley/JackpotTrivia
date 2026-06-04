//
//  AccessControlStoreTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class AccessControlStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AccessControlStore.resetForTesting()
        AccessControl.resetToDefaults()
        InviteLinkService.resetForTesting()
        PendingInviteStore.resetForTesting()
    }

    func testPersistAndLoad_accessMode() {
        AccessControl.accessMode = .openNotListed
        AccessControlStore.persistFromAccessControl()

        AccessControl.accessMode = .inviteOnly
        AccessControlStore.loadIntoAccessControl()

        XCTAssertEqual(AccessControl.accessMode, .openNotListed)
    }

    func testPersistAndLoad_memberCap() {
        AccessControl.maxMembers = 25
        AccessControlStore.persistFromAccessControl()

        AccessControl.maxMembers = nil
        AccessControlStore.loadIntoAccessControl()

        XCTAssertEqual(AccessControl.maxMembers, 25)
    }

    func testSyncMemberCount_matchesInviteService() {
        _ = InviteLinkService.registerMember()
        AccessControl.syncMemberCountFromInviteService()
        XCTAssertEqual(AccessControl.currentMemberCount, 1)
    }
}
