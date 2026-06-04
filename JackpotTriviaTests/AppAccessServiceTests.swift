//
//  AppAccessServiceTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class AppAccessServiceTests: XCTestCase {
    override func setUp() {
        LocalAppAccessService.resetForTesting()
        LocalAppAccessService.setGateEnabledForTesting(true)
    }

    func testValidCodeGrantsAccessAndIncrementsUsedCount() throws {
        _ = AppAccessAdminService.createAccessCode(code: "VALID1", maxUses: 2)
        XCTAssertFalse(LocalAppAccessService.shared.hasAppAccess)

        try LocalAppAccessService.shared.redeemAccessCode("valid1")
        XCTAssertTrue(LocalAppAccessService.shared.hasAppAccess)

        let code = AppAccessAdminService.listAccessCodes().first { $0.normalizedCode == "VALID1" }
        XCTAssertEqual(code?.usedCount, 1)
    }

    func testExpiredCodeRejected() {
        let expired = Date().addingTimeInterval(-60)
        _ = AppAccessAdminService.createAccessCode(code: "OLD", maxUses: nil, expiresAt: expired)

        XCTAssertThrowsError(try LocalAppAccessService.shared.redeemAccessCode("OLD")) { error in
            XCTAssertEqual(error as? AccessCodeRedemptionError, .invalidOrExpired)
        }
    }

    func testExhaustedCodeRejected() {
        _ = AppAccessAdminService.createAccessCode(code: "ONCE", maxUses: 1)
        try? LocalAppAccessService.shared.redeemAccessCode("ONCE")
        XCTAssertThrowsError(try LocalAppAccessService.shared.redeemAccessCode("ONCE"))
    }

    func testInactiveCodeRejected() {
        _ = AppAccessAdminService.createAccessCode(code: "OFF")
        AppAccessAdminService.deactivateAccessCode("OFF")

        XCTAssertThrowsError(try LocalAppAccessService.shared.redeemAccessCode("OFF"))
    }
}
