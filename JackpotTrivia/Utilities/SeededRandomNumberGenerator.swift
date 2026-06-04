//
//  SeededRandomNumberGenerator.swift
//  JackpotTrivia
//

import Foundation

/// Deterministic RNG for daily decks and stable unit tests.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state = state &* 6364136223846793005 &+ 1
    return state
  }
}
