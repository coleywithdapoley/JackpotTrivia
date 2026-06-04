//
//  Analytics.swift
//  JackpotTrivia
//
//  Type-safe analytics events and a swappable tracking protocol.
//  Replace ConsoleAnalyticsService with a Firebase/PostHog adapter later.
//

import Foundation
import SwiftUI

// MARK: - Events

enum AnalyticsEvent: Equatable {
    case appOpened
    case inviteValidated(codeLength: Int, result: InviteAnalyticsResult)
    case categoriesSelected(count: Int, categories: [String])
    case quizStarted(questionCount: Int)
    case questionAnswered(
        catalogID: String,
        isCorrect: Bool,
        category: String?,
        difficulty: String,
        timedOut: Bool,
        timeRemaining: Int
    )
    case questionReported(catalogID: String, reason: String)
    case quizCompleted(totalQuestions: Int, correctAnswers: Int)
    case adminSettingsChanged(
        accessMode: String,
        maxMembers: Int?,
        requireApproval: Bool
    )
    case leaderboardViewed(period: String)
    case scoreShared(points: Int)
    case challengeShared(points: Int)
    case appAccessRedeemed(success: Bool)
    case membershipRedeemed(success: Bool)
    case dailyStarted
    case dailyFinished(correct: Int, total: Int)
    case practiceStarted
    case loungeAccessBlocked
}

/// Analytics-facing invite outcome (no dependency on view-layer validation enums).
enum InviteAnalyticsResult: String, Equatable {
    case success
    case invalidCode
    case atCapacity
    case invitesDisabled
    case empty
    case tooShort
    case other

    static func from(validation: InviteCodeValidationResult) -> InviteAnalyticsResult {
        switch validation {
        case .valid: return .success
        case .invalid: return .invalidCode
        case .invitesDisabled: return .invitesDisabled
        case .empty: return .empty
        case .tooShort: return .tooShort
        }
    }

    static func from(access: AccessCheckResult) -> InviteAnalyticsResult {
        switch access {
        case .success: return .success
        case .invalidCode: return .invalidCode
        case .atCapacity: return .atCapacity
        case .inviteNotRequired: return .success
        case .invitesDisabled: return .invitesDisabled
        case .pendingApproval: return .other
        }
    }
}

// MARK: - Tracking protocol

protocol AnalyticsTracking: AnyObject {
    func track(_ event: AnalyticsEvent)
}

/// Release-safe no-op when no provider is configured.
final class NoOpAnalyticsService: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
}

// MARK: - Debug console implementation

final class ConsoleAnalyticsService: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(Self.describe(event))")
        #endif
    }

    static func describe(_ event: AnalyticsEvent) -> String {
        switch event {
        case .appOpened:
            return "app_opened"
        case .inviteValidated(let codeLength, let result):
            return "invite_validated codeLength=\(codeLength) result=\(result.rawValue)"
        case .categoriesSelected(let count, let categories):
            return "categories_selected count=\(count) categories=[\(categories.joined(separator: ", "))]"
        case .quizStarted(let questionCount):
            return "quiz_started questionCount=\(questionCount)"
        case .questionAnswered(let catalogID, let isCorrect, let category, let difficulty, let timedOut, let timeRemaining):
            let categoryPart = category.map { " category=\($0)" } ?? ""
            return "question_answered id=\(catalogID) isCorrect=\(isCorrect) difficulty=\(difficulty) timedOut=\(timedOut) timeRemaining=\(timeRemaining)\(categoryPart)"
        case .questionReported(let catalogID, let reason):
            return "question_reported id=\(catalogID) reason=\(reason)"
        case .quizCompleted(let total, let correct):
            return "quiz_completed totalQuestions=\(total) correctAnswers=\(correct)"
        case .adminSettingsChanged(let accessMode, let maxMembers, let requireApproval):
            let cap = maxMembers.map { "\($0)" } ?? "none"
            return "admin_settings_changed accessMode=\(accessMode) maxMembers=\(cap) requireApproval=\(requireApproval)"
        case .leaderboardViewed(let period):
            return "leaderboard_viewed period=\(period)"
        case .scoreShared(let points):
            return "score_shared points=\(points)"
        case .challengeShared(let points):
            return "challenge_shared points=\(points)"
        case .appAccessRedeemed(let success):
            return "app_access_redeemed success=\(success)"
        case .membershipRedeemed(let success):
            return "membership_redeemed success=\(success)"
        case .dailyStarted:
            return "daily_started"
        case .dailyFinished(let correct, let total):
            return "daily_finished correct=\(correct) total=\(total)"
        case .practiceStarted:
            return "practice_started"
        case .loungeAccessBlocked:
            return "lounge_access_blocked"
        }
    }
}

// MARK: - SwiftUI environment

private struct AnalyticsTrackingKey: EnvironmentKey {
    static let defaultValue: AnalyticsTracking = NoOpAnalyticsService()
}

extension EnvironmentValues {
    var analytics: AnalyticsTracking {
        get { self[AnalyticsTrackingKey.self] }
        set { self[AnalyticsTrackingKey.self] = newValue }
    }
}
