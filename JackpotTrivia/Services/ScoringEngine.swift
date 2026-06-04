//
//  ScoringEngine.swift
//  JackpotTrivia
//
//  Points formula for Phase 1 — speed bonus + streak bonus on top of difficulty base.
//

import Foundation

enum ScoringEngine {
  /// Maximum extra points from answering quickly (full time remaining).
  static let maxTimeBonus = 50

  /// Points added per consecutive correct answer (capped).
  static let streakBonusPerStep = 10
  static let maxStreakSteps = 5

  struct AnswerScore: Equatable {
    let base: Int
    let timeBonus: Int
    let streakBonus: Int

    var total: Int { base + timeBonus + streakBonus }
  }

  /// Computes points for one answered question.
  /// - Parameters:
  ///   - isCorrect: Whether the player chose the right answer.
  ///   - timeRemaining: Seconds left when submitted (0 if timed out).
  ///   - timeLimit: Total seconds for the question.
  ///   - difficulty: Question difficulty tier.
  ///   - streakAfterAnswer: Streak count *after* applying this answer (0 if wrong).
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

    let base = difficulty.basePoints
    let clampedRemaining = max(0, min(timeRemaining, timeLimit))
    let timeRatio = timeLimit > 0 ? Double(clampedRemaining) / Double(timeLimit) : 0
    let timeBonus = Int((timeRatio * Double(maxTimeBonus)).rounded())
    let streakSteps = min(max(0, streakAfterAnswer - 1), maxStreakSteps)
    let streakBonus = streakSteps * streakBonusPerStep

    return AnswerScore(base: base, timeBonus: timeBonus, streakBonus: streakBonus)
  }
}
