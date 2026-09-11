//
//  ScoringEngine.swift
//  JackpotTrivia
//
//  Points: 100 per correct answer + speed and streak bonuses.
//

import Foundation

enum ScoringEngine {
  /// Maximum extra points from answering quickly (full time remaining).
  static let maxTimeBonus = 25

  /// Points added per consecutive correct answer after the first (capped).
  static let streakBonusPerStep = 10
  static let maxStreakSteps = 3

  struct AnswerScore: Equatable {
    let base: Int
    let timeBonus: Int
    let streakBonus: Int

    var total: Int { base + timeBonus + streakBonus }

    /// Human-readable breakdown for in-game feedback.
    var breakdownLabel: String {
      var parts = ["\(base) base"]
      if timeBonus > 0 { parts.append("+\(timeBonus) speed") }
      if streakBonus > 0 { parts.append("+\(streakBonus) streak") }
      return parts.joined(separator: " · ")
    }
  }

  /// Computes points for one answered question.
  static func score(
    isCorrect: Bool,
    timeRemaining: Int,
    timeLimit: Int,
    difficulty: QuestionDifficulty,
    streakAfterAnswer: Int
  ) -> AnswerScore {
    guard isCorrect else {
      return AnswerScore(base: 0, timeBonus: 0, streakBonus: 0)
    }

    let base = AppConfig.pointsPerCorrectAnswer
    let clampedRemaining = max(0, min(timeRemaining, timeLimit))
    let timeRatio = timeLimit > 0 ? Double(clampedRemaining) / Double(timeLimit) : 0
    let timeBonus = Int((timeRatio * Double(maxTimeBonus)).rounded())
    let streakSteps = min(max(0, streakAfterAnswer - 1), maxStreakSteps)
    let streakBonus = streakSteps * streakBonusPerStep

    return AnswerScore(base: base, timeBonus: timeBonus, streakBonus: streakBonus)
  }
}
