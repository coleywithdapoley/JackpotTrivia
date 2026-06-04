//
//  AuthManager.swift
//  JackpotTrivia
//

import Combine
import Foundation

@MainActor
final class AuthManager: ObservableObject {
  static let shared = AuthManager()

  @Published private(set) var currentUser: AuthUser?

  private let service: AuthServiceProtocol

  var isAuthenticated: Bool { currentUser != nil }

  init(service: AuthServiceProtocol = BackendEnvironment.makeAuthService()) {
    self.service = service
    self.currentUser = service.currentUser
  }

  func signIn(email: String, password: String) async throws {
    let user = try await service.signIn(email: email, password: password)
    currentUser = user
    await BackendEnvironment.bootstrap()
  }

  func signUp(email: String, password: String, displayName: String?) async throws {
    let user = try await service.signUp(email: email, password: password, displayName: displayName)
    currentUser = user
    await BackendEnvironment.bootstrap()
  }

  func signOut() {
    service.signOut()
    currentUser = nil
  }

  func sendPasswordResetEmail(to email: String) async throws {
    try await service.sendPasswordResetEmail(to: email)
  }

  func sendPasswordResetSMS(to phoneNumber: String) async throws {
    try await service.sendPasswordResetSMS(to: phoneNumber)
  }

  func redeemMembershipCode(_ code: String) throws {
    guard let userID = currentUser?.id else {
      throw AccessCodeRedemptionError.invalidOrExpired
    }
    let tier = try LocalMembershipService.shared.redeem(code: code, for: userID)
    service.updateMembershipTier(tier, for: userID)
    currentUser?.membershipTier = tier
    PrivateAccessStore.grantAccess()
  }

  func refreshMembershipTier() {
    guard let user = currentUser else { return }
    let tier = LocalMembershipService.shared.currentTier(for: user.id)
    if tier != user.membershipTier {
      currentUser?.membershipTier = tier
    }
  }

  var isMember: Bool {
    currentUser?.membershipTier.isMember == true
  }
}
