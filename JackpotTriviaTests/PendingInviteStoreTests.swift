//
//  PendingInviteStoreTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class PendingInviteStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PendingInviteStore.resetForTesting()
        InstallationIDService.resetForTesting()
    }

    func testApprove_marksInstallationApproved() {
        PendingInviteStore.submit(rawInvite: "TRIVIA2026")
        XCTAssertFalse(PendingInviteStore.isInstallationApproved())

        PendingInviteStore.approve(installationID: InstallationIDService.id)

        XCTAssertTrue(PendingInviteStore.isInstallationApproved())
        XCTAssertTrue(PendingInviteStore.allPending().isEmpty)
    }
}
