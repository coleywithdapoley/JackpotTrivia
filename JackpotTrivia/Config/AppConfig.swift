//
//  AppConfig.swift
//  JackpotTrivia
//
//  Central client-facing configuration. Edit this file for branding, invites,
//  categories, and default copy before shipping or handoff.
//

import SwiftUI

enum AppConfig {
    // MARK: - Brand & naming

    /// In-app title; keep aligned with Info.plist `CFBundleDisplayName` / AppBranding.bundleDisplayName.
    static let appDisplayName = AppBranding.bundleDisplayName

    /// Primary brand green on white. Used by DesignSystem and UI chrome.
    static let primaryAccentColor = Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255)

    // MARK: - Phase 1: Daily jackpot & rewards

    /// Questions in the official daily run (before feature-gate cap).
    static let dailyQuestionCount = 10

    /// Salt for deterministic daily deck shuffle — change per environment/season.
    static let dailyDeckSalt = "jackpot-phase1"

    /// Demo conversion for wallet UI (not real money).
    static let pointsPerDollarDisplay = 1000

    /// When false, authenticated users go straight to the daily hub (wide audience).
    /// Set true for invite-only launch (download app, need code from founders).
    static let requiresInviteAfterAuth = false

    /// When true, show app access code screen before auth (separate from lounge membership).
    static let requireAppAccessCode = false

    /// Warmup question count for first session (does not consume daily jackpot).
    static let onboardingWarmupQuestionCount = 5

    /// Minimum practice pool before allowing jackpot overlap fallback.
    static let minimumPracticePoolSize = 3

    // MARK: - Access & invites

    /// Tier-1 founder codes — redeemers become founders (large invite quota).
    static let founderInviteCodes: [String] = ["TRIVIA2026", "VIP123"]

    /// Legacy / general invite codes (tier-2 member on redeem).
    static let defaultInviteCodes: [String] = ["TRIVIA2026", "VIP123", "BETA2026"]

    /// Max private links a founder may create (tier 1).
    static let founderReferralLimit = 50

    /// Max private links per tier-2 member (conversation: ~2 each).
    static let tier2ReferralLimit = 2

    /// Questions in a private lounge round.
    static let privateLoungeQuestionCount = 10

    /// `nil` = no member cap. Enforced when backend or join counting is added.
    static let defaultMaxMembers: Int? = nil

    static let minimumInviteCodeLength = 5

    /// Used when an admin enables a member cap in settings UI.
    static let defaultMemberLimitWhenEnabled = 50

    // MARK: - Monetization (no StoreKit yet)

    /// Drives `FeatureGates` until StoreKit entitlements override this at launch.
    /// Use `.premium` for TestFlight / reviewer full access; ship with `.free` for freemium.
    /// TODO: Replace with StoreKit 2 `Transaction.currentEntitlements` (or equivalent) at app start.
    static let defaultAccessTier: AccessTier = .free

    // MARK: - Categories

    /// Category names shown in category selection and used to filter QuestionBank.
    /// Keep in sync with question `category` fields in QuestionBank.swift.
    static let defaultCategories: [String] = [
        "General Knowledge",
        "Science",
        "History",
        "Sports",
        "Movies & TV",
        "Music",
    ]

    static let categoryEmoji: [String: String] = [
        "General Knowledge": "🧠",
        "Science": "🔬",
        "History": "📜",
        "Sports": "⚽️",
        "Movies & TV": "🎬",
        "Music": "🎵",
    ]

    static let categoryDescriptions: [String: String] = [
        "General Knowledge": "A bit of everything",
        "Science": "Facts and discovery",
        "History": "Past events and figures",
        "Sports": "Games, teams, and records",
        "Movies & TV": "Screens big and small",
        "Music": "Artists, songs, and genres",
    ]

    static func emoji(forCategory name: String) -> String? {
        categoryEmoji[name]
    }

    static func description(forCategory name: String) -> String? {
        categoryDescriptions[name]
    }

    /// Categories pulled automatically for each trivia mood.
    static func categories(for mood: TriviaMood) -> [String] {
        switch mood {
        case .deepConversations:
            return ["History", "General Knowledge"]
        case .funnyAndWild:
            return ["Movies & TV", "Music", "Sports"]
        case .dateNight:
            return ["Movies & TV", "Music", "General Knowledge"]
        case .familyGameNight:
            return ["General Knowledge", "Science", "Sports"]
        case .learnSomethingNew:
            return ["Science", "History", "General Knowledge"]
        case .debateMode:
            return ["History", "General Knowledge"]
        case .custom:
            return []
        }
    }

    // MARK: - User-facing copy

    enum Copy {
        static let tagline = "Daily trivia for grown folks — bragging rights, not bets."
        static let authSubtitle = "Invite-friendly daily trivia for 18+ players."
        static let dailyJackpotTitle = "Today's Jackpot"
        static let dailyJackpotSubtitle = "One official run per day — timed questions, instant feedback, difficulty tiers."
        static let prizeDisclaimer = "XP has no cash value. Points are for bragging rights and in-app progression only."
        static let xpBankTitle = "Score bank"
        static let accessCodeTitle = "Enter your access code to join"
        static let accessCodeFooter = "Membership is separate — unlock the lounge later with a lounge code from the founders."
        static let loungeCodeTitle = "Lounge code"
        static let loungeMembersOnly = "Members only. Enter a lounge code from the admins to unlock the 18+ lounge."
        static let inviteFieldLabel = "Invite Code"
        static let invitePlaceholder = "Enter invite code"
        static let inviteFooterNote = "Access is managed by administration."
        static let inviteEmptyMessage = "Please enter your invite code"
        static let inviteTooShortMessage = "Invite code looks too short"
        static let inviteInvalidMessage = "That invite code is not valid"
        static let inviteDisabledMessage = "Invite codes are not accepted right now"

        static let resultsEmptyMessage = "Start a round from category selection to see your results here."
        static let resultsHighScoreMessage = "Nice work! You really know your stuff."
        static let resultsEncourageMessage = "Good effort! Want to try again and beat your score?"

        static let highScoreAccuracyThreshold = 70
    }
}
