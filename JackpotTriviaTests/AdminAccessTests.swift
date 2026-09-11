//
//  AdminAccessTests.swift
//  JackpotTriviaTests
//

import XCTest
@testable import JackpotTrivia

final class AdminAccessTests: XCTestCase {
    private let allowlist: Set<String> = ["founder@example.com", "  Kwan@Example.COM "]

    func testAllowlistedEmailIsAdmin() {
        XCTAssertTrue(AdminAccess.isAdmin(email: "founder@example.com", allowlist: allowlist))
    }

    func testPlayerEmailIsNotAdmin() {
        XCTAssertFalse(AdminAccess.isAdmin(email: "player@example.com", allowlist: allowlist))
    }

    func testEmailMatchIsCaseAndWhitespaceInsensitive() {
        XCTAssertTrue(AdminAccess.isAdmin(email: "  FOUNDER@EXAMPLE.COM  ", allowlist: allowlist))
        XCTAssertTrue(AdminAccess.isAdmin(email: "kwan@example.com", allowlist: allowlist))
    }

    func testEmptyEmailIsNotAdmin() {
        XCTAssertFalse(AdminAccess.isAdmin(email: "   ", allowlist: allowlist))
        XCTAssertFalse(AdminAccess.isAdmin(email: "", allowlist: []))
    }

    func testSeededAdminAccountIsAdmin() {
        XCTAssertTrue(AdminAccess.isAdmin(email: AppConfig.adminEmail))
        XCTAssertTrue(AuthUser(id: "admin", email: AppConfig.adminEmail).isAdmin)
        XCTAssertFalse(AdminAccess.isAdmin(email: "cobb.cole@gmail.com"))
        XCTAssertFalse(AuthUser(id: "player", email: "player@example.com").isAdmin)
    }

    func testSeededAdminSignIn() async throws {
        let user = try await LocalAuthService.shared.signIn(
            email: AppConfig.adminEmail,
            password: AppConfig.adminPassword
        )
        XCTAssertEqual(user.email, AppConfig.adminEmail.lowercased())
        XCTAssertTrue(user.isAdmin)
        LocalAuthService.shared.signOut()
    }

    func testAdminQuestionSlugIsPlainTextDerived() {
        let slug = AdminQuestionSlug.make(from: "Who founded Motown Records?")
        XCTAssertTrue(slug.hasPrefix("admin-who-founded-motown-records-"))
        XCTAssertFalse(slug.contains("{"))
        XCTAssertFalse(slug.contains(" "))
    }
}
