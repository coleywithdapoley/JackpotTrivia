//
//  DailyGameService.swift
//  JackpotTrivia
//
//  Client-side daily deck until the backend serves an official question set per day.
//

import Foundation

enum DailyGameService {
  private static let lastCompletedDateKey = "jackpotTrivia.daily.lastCompletedDate"

  /// Calendar day key in the user's current timezone (yyyy-MM-dd).
  static func dayKey(for date: Date = .now) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  static var hasCompletedDailyToday: Bool {
    UserDefaults.standard.string(forKey: lastCompletedDateKey) == dayKey()
  }

  static func markDailyCompleted(on date: Date = .now) {
    UserDefaults.standard.set(dayKey(for: date), forKey: lastCompletedDateKey)
  }

  static func resetDailyCompletionForTesting() {
    UserDefaults.standard.removeObject(forKey: lastCompletedDateKey)
    DailyJackpotDeckStore.resetForTesting()
  }

  /// Official daily jackpot deck — cached per calendar day.
  static func questionsForDailyJackpot(
    profile: UserContentProfile = UserProfileStore.profile,
    count: Int = AppConfig.dailyQuestionCount,
    date: Date = .now,
    using pool: [TriviaQuestion] = QuestionBank.allQuestions
  ) -> [TriviaQuestion] {
    let key = dayKey(for: date)

    if let cachedIDs = DailyJackpotDeckStore.deckIDs(for: key) {
      let resolved = resolveQuestions(ids: cachedIDs, from: pool)
      if resolved.count == cachedIDs.count {
        return Array(resolved.prefix(count))
      }
    }

    if let official = QuestionRepository.shared.dailyQuestionsForToday(profile: profile, count: count) {
      DailyJackpotDeckStore.saveDeckIDs(official.map(\.catalogID), for: key)
      return official
    }

    let jackpotPool = QuestionBank.filteredQuestions(for: [], profile: profile, from: pool)
      .filter(\.isJackpotEligible)
    let source = jackpotPool.isEmpty ? pool.filter(\.isJackpotEligible) : jackpotPool
    var generator = SeededRandomNumberGenerator(seed: dailySeed(for: date))
    let shuffled = source.shuffled(using: &generator)
    let selected = Array(shuffled.prefix(count))
    DailyJackpotDeckStore.saveDeckIDs(selected.map(\.catalogID), for: key)
    return selected
  }

  /// Backward-compatible alias.
  static func questionsForToday(
    profile: UserContentProfile = UserProfileStore.profile,
    count: Int = AppConfig.dailyQuestionCount,
    date: Date = .now,
    using pool: [TriviaQuestion] = QuestionBank.allQuestions
  ) -> [TriviaQuestion] {
    questionsForDailyJackpot(profile: profile, count: count, date: date, using: pool)
  }

  static func todaysJackpotQuestionIDs(date: Date = .now) -> Set<String> {
    Set(DailyJackpotDeckStore.deckIDs(for: dayKey(for: date)) ?? [])
  }

  private static func resolveQuestions(ids: [String], from pool: [TriviaQuestion]) -> [TriviaQuestion] {
    let byID = Dictionary(uniqueKeysWithValues: pool.map { ($0.catalogID, $0) })
    return ids.compactMap { byID[$0] }
  }

  private static func dailySeed(for date: Date) -> UInt64 {
    var hasher = Hasher()
    hasher.combine(dayKey(for: date))
    hasher.combine(AppConfig.dailyDeckSalt)
    return UInt64(bitPattern: Int64(hasher.finalize()))
  }
}
