//
//  SupabaseAuthService.swift
//  JackpotTrivia
//

import Foundation

/// Supabase GoTrue auth. Falls back to errors when secrets are missing.
final class SupabaseAuthService: AuthServiceProtocol {
    static let shared = SupabaseAuthService()

    private let client: SupabaseHTTPClient?

    private(set) var currentUser: AuthUser?

    private init() {
        client = SupabaseHTTPClient()
        currentUser = Self.user(from: SupabaseSessionStore.current)
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        guard let client else { throw AuthError.networkUnavailable }
        let normalized = normalizeEmail(email)
        let body = TokenRequest(email: normalized, password: password)
        let data = try await client.post(path: "/auth/v1/token?grant_type=password", body: body)
        let response = try decodeAuthResponse(data)
        guard response.accessToken != nil else {
            throw AuthError.message("Confirm this email, then try Sign In again.")
        }
        try persistSession(response)
        let user = try await upsertProfileIfNeeded(response: response, displayName: nil)
        currentUser = user
        return user
    }

    func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
        guard let client else { throw AuthError.networkUnavailable }
        let normalized = normalizeEmail(email)
        guard isValidEmail(normalized) else { throw AuthError.invalidEmail }
        guard password.count >= 8 else { throw AuthError.weakPassword }

        let body = SignUpRequest(
            email: normalized,
            password: password,
            data: SignUpMetadata(displayName: displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)
        )
        let data = try await client.post(path: "/auth/v1/signup", body: body)
        let response = try decodeAuthResponse(data)
        guard response.accessToken != nil else {
            throw AuthError.message("Account created. If you don’t get a session, tap Sign In with the same email and password.")
        }
        try persistSession(response)
        let user = try await upsertProfileIfNeeded(response: response, displayName: displayName)
        currentUser = user
        return user
    }

    func signOut() {
        SupabaseSessionStore.clear()
        currentUser = nil
    }

    func sendPasswordResetEmail(to email: String) async throws {
        guard let client else { throw AuthError.networkUnavailable }
        let normalized = normalizeEmail(email)
        guard isValidEmail(normalized) else { throw AuthError.invalidEmail }
        _ = try await client.post(
            path: "/auth/v1/recover",
            body: RecoverRequest(email: normalized)
        )
    }

    func sendPasswordResetSMS(to phoneNumber: String) async throws {
        throw AuthError.message("SMS password reset requires Supabase phone auth configuration.")
    }

    func updateMembershipTier(_ tier: MembershipTier, for userID: String) {
        LocalMembershipService.shared.persistTier(tier, for: userID)
        if currentUser?.id == userID {
            currentUser?.membershipTier = tier
        }
    }

    var accessToken: String? {
        SupabaseSessionStore.current?.accessToken
    }

    // MARK: - Private

    private struct TokenRequest: Encodable {
        let grantType = "password"
        let email: String
        let password: String

        enum CodingKeys: String, CodingKey {
            case grantType = "grant_type"
            case email
            case password
        }
    }

    private struct SignUpRequest: Encodable {
        let email: String
        let password: String
        let data: SignUpMetadata?
    }

    private struct SignUpMetadata: Encodable {
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    private struct RecoverRequest: Encodable {
        let email: String
    }

    private struct AuthUserPayload: Decodable {
        let id: String
        let email: String?
        let userMetadata: UserMetadata?

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case userMetadata = "user_metadata"
        }

        struct UserMetadata: Decodable {
            let displayName: String?

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
            }
        }
    }

    private struct AuthResponse: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let expiresIn: Int?
        let user: AuthUserPayload

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case user
        }
    }

    private func decodeAuthResponse(_ data: Data) throws -> AuthResponse {
        let decoder = JSONDecoder()
        if let response = try? decoder.decode(AuthResponse.self, from: data) {
            return response
        }
        struct ErrorBody: Decodable {
            let msg: String?
            let message: String?
            let errorDescription: String?

            enum CodingKeys: String, CodingKey {
                case msg
                case message
                case errorDescription = "error_description"
            }
        }
        if let err = try? decoder.decode(ErrorBody.self, from: data) {
            let text = err.msg ?? err.message ?? err.errorDescription ?? "Authentication failed."
            if text.localizedCaseInsensitiveContains("already") {
                throw AuthError.emailAlreadyRegistered
            }
            if text.localizedCaseInsensitiveContains("invalid") && text.localizedCaseInsensitiveContains("email") {
                throw AuthError.invalidEmail
            }
            if text.localizedCaseInsensitiveContains("confirm") {
                throw AuthError.message("Confirm this email, then try Sign In again.")
            }
            if text.localizedCaseInsensitiveContains("password") && !text.localizedCaseInsensitiveContains("credentials") {
                throw AuthError.weakPassword
            }
            throw AuthError.message(text)
        }
        throw AuthError.invalidCredentials
    }

    private func persistSession(_ response: AuthResponse) throws {
        guard let accessToken = response.accessToken, let refreshToken = response.refreshToken else {
            throw AuthError.invalidCredentials
        }
        let expiresAt = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        let session = SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userID: response.user.id,
            email: response.user.email ?? "",
            displayName: response.user.userMetadata?.displayName,
            expiresAt: expiresAt
        )
        SupabaseSessionStore.save(session)
    }

    private func upsertProfileIfNeeded(response: AuthResponse, displayName: String?) async throws -> AuthUser {
        let name = displayName?.nilIfEmpty
            ?? response.user.userMetadata?.displayName
            ?? response.user.email?.split(separator: "@").first.map(String.init)

        if let client, let token = SupabaseSessionStore.current?.accessToken {
            let body = ProfileUpsert(
                id: response.user.id,
                email: response.user.email ?? "",
                displayName: name
            )
            _ = try? await client.post(
                path: "/rest/v1/profiles",
                body: [body],
                accessToken: token,
                prefer: "resolution=merge-duplicates"
            )
        }

        return AuthUser(
            id: response.user.id,
            email: response.user.email ?? "",
            phoneNumber: nil,
            displayName: name,
            membershipTier: LocalMembershipService.shared.currentTier(for: response.user.id)
        )
    }

    private struct ProfileUpsert: Encodable {
        let id: String
        let email: String
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case displayName = "display_name"
        }
    }

    private static func user(from session: SupabaseSession?) -> AuthUser? {
        guard let session else { return nil }
        let tier = LocalMembershipService.shared.currentTier(for: session.userID)
        return AuthUser(
            id: session.userID,
            email: session.email,
            phoneNumber: nil,
            displayName: session.displayName,
            membershipTier: tier
        )
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".") && email.count >= 5
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
