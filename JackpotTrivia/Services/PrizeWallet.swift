//
//  PrizeWallet.swift
//  JackpotTrivia
//
//  Demo reward points until real cash payouts and compliance are wired.
//

import Foundation

enum PrizeWallet {
  private static let balanceKey = "jackpotTrivia.prize.pointsBalance"
  private static let lifetimeKey = "jackpotTrivia.prize.lifetimePoints"

  static var pointsBalance: Int {
    get { UserDefaults.standard.integer(forKey: balanceKey) }
    set { UserDefaults.standard.set(newValue, forKey: balanceKey) }
  }

  static var lifetimePoints: Int {
    get { UserDefaults.standard.integer(forKey: lifetimeKey) }
    set { UserDefaults.standard.set(newValue, forKey: lifetimeKey) }
  }

  /// Demo conversion copy only — not real money until payouts are enabled.
  static var estimatedCashDisplay: String {
    let dollars = Double(pointsBalance) / Double(AppConfig.pointsPerDollarDisplay)
    return String(format: "$%.2f", dollars)
  }

  @discardableResult
  static func creditRound(points: Int) -> Int {
    guard points > 0 else { return pointsBalance }
    pointsBalance += points
    lifetimePoints += points
    return pointsBalance
  }

  static func resetForTesting() {
    pointsBalance = 0
    lifetimePoints = 0
  }
}
