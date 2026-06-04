//
//  AccessControlTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class AccessControlTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AccessControlStore.resetForTesting()
        AccessControl.resetToDefaults()
    }

    func testValidateInvite_succeedsForValidCode() {
        AccessControl.validInviteCodes = ["TRIVIA2026"]
        AccessControl.accessMode = .inviteOnly
        AccessControl.maxMembers = nil
        AccessControl.currentMemberCount = 0

        let result = AccessControl.validateInvite(code: "TRIVIA2026")

        XCTAssertEqual(result, .success)
    }

    func testValidateInvite_succeedsWhenCodeHasDifferentCasing() {
        AccessControl.validInviteCodes = ["TRIVIA2026"]

        let result = AccessControl.validateInvite(code: "trivia2026")

        XCTAssertEqual(result, .success)
    }

    func testValidateInvite_returnsInvalidCodeForUnknownCode() {
        AccessControl.validInviteCodes = ["TRIVIA2026"]

        let result = AccessControl.validateInvite(code: "WRONG")

        XCTAssertEqual(result, .invalidCode)
    }

    func testValidateInvite_returnsAtCapacityWhenMemberLimitReached() {
        AccessControl.validInviteCodes = ["TRIVIA2026"]
        AccessControl.maxMembers = 2
        AccessControl.currentMemberCount = 2

        let result = AccessControl.validateInvite(code: "TRIVIA2026")

        XCTAssertEqual(result, .atCapacity)
    }

    func testValidateInvite_returnsInviteNotRequiredForOpenNotListedMode() {
        AccessControl.accessMode = .openNotListed
        AccessControl.validInviteCodes = ["TRIVIA2026"]

        let result = AccessControl.validateInvite(code: "anything-goes")

        XCTAssertEqual(result, .inviteNotRequired)
    }

    func testValidateInvite_returnsInvitesDisabledWhenCodesTurnedOff() {
        AccessControl.allowInviteCodes = false
        AccessControl.accessMode = .inviteOnly

        let result = AccessControl.validateInvite(code: "TRIVIA2026")

        XCTAssertEqual(result, .invitesDisabled)
    }

    func testResetToDefaults_restoresAppConfigValues() {
        AccessControl.validInviteCodes = ["CUSTOM"]
        AccessControl.maxMembers = 99
        AccessControl.currentMemberCount = 5
        AccessControl.accessMode = .openNotListed
        AccessControl.allowInviteCodes = false

        AccessControl.resetToDefaults()

        XCTAssertTrue(
            AccessControl.validInviteCodes.contains(
                AccessControl.normalizeInviteCode(AppConfig.defaultInviteCodes[0])
            )
        )
        XCTAssertEqual(AccessControl.maxMembers, AppConfig.defaultMaxMembers)
        XCTAssertEqual(AccessControl.currentMemberCount, 0)
        XCTAssertEqual(AccessControl.accessMode, .inviteOnly)
        XCTAssertTrue(AccessControl.allowInviteCodes)
    }
}
