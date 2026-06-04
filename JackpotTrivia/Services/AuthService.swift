//
//  AuthService.swift
//  JackpotTrivia
//
//  Auth contract for Phase 1. Replace LocalAuthService with Supabase/Firebase when backend is ready.
//

import Foundation

struct AuthUser: Equatable, Codable, Identifiable {
  let id: String
  let email: String
  var phoneNumber: String?
  var displayName: String?
  var membershipTier: MembershipTier

  init(
    id: String,
    email: String,
    phoneNumber: String? = nil,
    displayName: String? = nil,
    membershipTier: MembershipTier = .free
  ) {
    self.id = id
    self.email = email
    self.phoneNumber = phoneNumber
    self.displayName = displayName
    self.membershipTier = membershipTier
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    email = try container.decode(String.self, forKey: .email)
    phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
    displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
    membershipTier = try container.decodeIfPresent(MembershipTier.self, forKey: .membershipTier) ?? .free
  }
}

enum AuthError: LocalizedError, Equatable {
  case invalidCredentials
  case emailAlreadyRegistered
  case weakPassword
  case invalidEmail
  case userNotFound
  case networkUnavailable
  case message(String)

  var errorDescription: String? {
    switch self {
    case .invalidCredentials: return "Email or password is incorrect."
    case .emailAlreadyRegistered: return "An account with this email already exists."
    case .weakPassword: return "Password must be at least 8 characters."
    case .invalidEmail: return "Enter a valid email address."
    case .userNotFound: return "No account found for that email."
    case .networkUnavailable: return "Unable to reach the server. Try again."
    case .message(let text): return text
    }
  }
}

protocol AuthServiceProtocol: AnyObject {
  var currentUser: AuthUser? { get }
  func signIn(email: String, password: String) async throws -> AuthUser
  func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser
  func signOut()
  func sendPasswordResetEmail(to email: String) async throws
  func sendPasswordResetSMS(to phoneNumber: String) async throws
  func updateMembershipTier(_ tier: MembershipTier, for userID: String)
}

/// Device-local mock auth (UserDefaults). Do not use for production security.
final class LocalAuthService: AuthServiceProtocol {
  static let shared = LocalAuthService()

  private let usersKey = "jackpotTrivia.auth.users"
  private let sessionKey = "jackpotTrivia.auth.sessionUserId"

  private(set) var currentUser: AuthUser?

  private init() {
    currentUser = loadSessionUser()
  }

  func signIn(email: String, password: String) async throws -> AuthUser {
    try await simulateNetwork()
    let normalized = normalizeEmail(email)
    guard let stored = loadUsers()[normalized] else {
      throw AuthError.invalidCredentials
    }
    guard stored.password == password else {
      throw AuthError.invalidCredentials
    }
    let user = stored.user.withMembershipTier(LocalMembershipService.shared.currentTier(for: stored.user.id))
    persistSession(userID: user.id)
    currentUser = user
    return user
  }

  func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
    try await simulateNetwork()
    let normalized = normalizeEmail(email)
    guard isValidEmail(normalized) else { throw AuthError.invalidEmail }
    guard password.count >= 8 else { throw AuthError.weakPassword }

    var users = loadUsers()
    if users[normalized] != nil {
      throw AuthError.emailAlreadyRegistered
    }

    let user = AuthUser(
      id: UUID().uuidString,
      email: normalized,
      phoneNumber: nil,
      displayName: displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
      membershipTier: .free
    )
    users[normalized] = StoredUser(user: user, password: password)
    saveUsers(users)
    persistSession(userID: user.id)
    currentUser = user
    return user
  }

  func updateMembershipTier(_ tier: MembershipTier, for userID: String) {
    var users = loadUsers()
    guard let key = users.first(where: { $0.value.user.id == userID })?.key else { return }
    users[key]?.user.membershipTier = tier
    saveUsers(users)
    if currentUser?.id == userID {
      currentUser = users[key]?.user
    }
    LocalMembershipService.shared.persistTier(tier, for: userID)
  }

  func signOut() {
    UserDefaults.standard.removeObject(forKey: sessionKey)
    currentUser = nil
  }

  func sendPasswordResetEmail(to email: String) async throws {
    try await simulateNetwork()
    let normalized = normalizeEmail(email)
    guard isValidEmail(normalized) else { throw AuthError.invalidEmail }
    guard loadUsers()[normalized] != nil else { throw AuthError.userNotFound }
    // Mock: no email sent
  }

  func sendPasswordResetSMS(to phoneNumber: String) async throws {
    try await simulateNetwork()
    let digits = phoneNumber.filter(\.isNumber)
    guard digits.count >= 10 else {
      throw AuthError.message("Enter a valid phone number.")
    }
    // Mock: no SMS sent
  }

  // MARK: - Helpers

  private struct StoredUser: Codable {
    var user: AuthUser
    var password: String
  }

  private func loadUsers() -> [String: StoredUser] {
    guard let data = UserDefaults.standard.data(forKey: usersKey),
          let decoded = try? JSONDecoder().decode([String: StoredUser].self, from: data) else {
      return [:]
    }
    return decoded
  }

  private func saveUsers(_ users: [String: StoredUser]) {
    if let data = try? JSONEncoder().encode(users) {
      UserDefaults.standard.set(data, forKey: usersKey)
    }
  }

  private func loadSessionUser() -> AuthUser? {
    guard let userID = UserDefaults.standard.string(forKey: sessionKey),
          var user = loadUsers().values.first(where: { $0.user.id == userID })?.user else { return nil }
    user.membershipTier = LocalMembershipService.shared.currentTier(for: userID)
    return user
  }

  private func persistSession(userID: String) {
    UserDefaults.standard.set(userID, forKey: sessionKey)
  }

  private func normalizeEmail(_ email: String) -> String {
    email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private func isValidEmail(_ email: String) -> Bool {
    email.contains("@") && email.contains(".") && email.count >= 5
  }

  private func simulateNetwork() async throws {
    try await Task.sleep(nanoseconds: 250_000_000)
  }
}

private extension AuthUser {
  func withMembershipTier(_ tier: MembershipTier) -> AuthUser {
    var copy = self
    copy.membershipTier = tier
    return copy
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
