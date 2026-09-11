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

    /// Detroit lime accent — mirrored in Assets `BrandPrimary`. Prefer `AppColors.brandPrimary` in views.
    static let primaryAccentColor = AppColors.brandPrimary

    // MARK: - Phase 1: Daily jackpot & rewards

    /// Questions in the official daily run (before feature-gate cap).
    static let dailyQuestionCount = 10

    /// Salt for deterministic daily deck shuffle — change per environment/season.
    static let dailyDeckSalt = "jackpot-phase1"

    /// Demo conversion for score bank UI (not real money).
    static let pointsPerDollarDisplay = 1000

    /// Points awarded for each correct answer (before speed and streak bonuses).
    static let pointsPerCorrectAnswer = 100

    /// When false, authenticated users go straight to the daily hub (wide audience).
    /// Set true for invite-only launch (download app, need code from founders).
    static let requiresInviteAfterAuth = false

    /// When true, show app access code screen before auth (separate from lounge membership).
    static let requireAppAccessCode = false

    /// Seeded admin account. Sign in with these credentials to open Admin Access Settings.
    /// Players who create their own accounts are never admin.
    static let adminEmail = "admin@ifyouknowyouwin.app"
    static let adminPassword = "Admin2026!"
    static let adminDisplayName = "Admin"
    static var adminEmails: Set<String> { [adminEmail] }

    /// Warmup segment length inside the first official daily jackpot run.
    static let onboardingWarmupQuestionCount = 5

    /// Guest Detroit Quick Hit — no account required.
    static let quickHitQuestionCount = 3

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

    // MARK: - Categories (Detroit-themed)

    /// Category names shown in category selection and used to filter QuestionBank.
    /// Keep in sync with question `category` fields in QuestionCatalog.json.
    static let defaultCategories: [String] = [
        "Motown & Music",
        "Detroit Sports",
        "Auto City",
        "Local Legends",
        "Downtown & Neighborhoods",
    ]

    /// Categories counted as Detroit-themed for daily jackpot deck bias.
    static let detroitThemedCategories: Set<String> = Set(defaultCategories)

    /// Minimum Detroit-category questions in each daily jackpot run (≥ half of `dailyQuestionCount`).
    static var minimumDetroitQuestionsPerDailyJackpot: Int {
        max(1, dailyQuestionCount / 2)
    }

    static let categoryEmoji: [String: String] = [
        "Motown & Music": "🎵",
        "Detroit Sports": "🏈",
        "Auto City": "🚗",
        "Local Legends": "⭐",
        "Downtown & Neighborhoods": "🏙️",
    ]

    /// Asset catalog image names for category thumbnails (`Category*.imageset`).
    static let categoryImageAsset: [String: String] = [
        "Motown & Music": "CategoryMotownMusic",
        "Detroit Sports": "CategoryDetroitSports",
        "Auto City": "CategoryAutoCity",
        "Local Legends": "CategoryLocalLegends",
        "Downtown & Neighborhoods": "CategoryDowntownNeighborhoods",
    ]

    static let categoryDescriptions: [String: String] = [
        "Motown & Music": "Hitsville, soul, hip-hop, and Detroit sound",
        "Detroit Sports": "Lions, Tigers, Red Wings, Pistons, and Motor City sports lore",
        "Auto City": "Assembly lines, automakers, and industrial Detroit",
        "Local Legends": "Icons, history-makers, and hometown heroes",
        "Downtown & Neighborhoods": "Streets, landmarks, and city culture",
    ]

    static func emoji(forCategory name: String) -> String? {
        categoryEmoji[name]
    }

    static func imageAsset(forCategory name: String) -> String? {
        categoryImageAsset[name]
    }

    static func description(forCategory name: String) -> String? {
        categoryDescriptions[name]
    }

    /// Categories pulled automatically for each trivia mood.
    static func categories(for mood: TriviaMood) -> [String] {
        switch mood {
        case .deepConversations:
            return ["Local Legends", "Downtown & Neighborhoods"]
        case .funnyAndWild:
            return ["Motown & Music", "Detroit Sports", "Local Legends"]
        case .dateNight:
            return ["Motown & Music", "Downtown & Neighborhoods", "Local Legends"]
        case .familyGameNight:
            return ["Downtown & Neighborhoods", "Auto City", "Detroit Sports"]
        case .learnSomethingNew:
            return ["Auto City", "Local Legends", "Downtown & Neighborhoods"]
        case .debateMode:
            return ["Local Legends", "Downtown & Neighborhoods"]
        case .custom:
            return []
        }
    }

    static func isDetroitThemedCategory(_ category: String) -> Bool {
        detroitThemedCategories.contains(category)
    }

    // MARK: - User-facing copy

    enum Copy {
        static let tagline = "If you know, you win — bragging rights, not bets."
        static let authSubtitle = "Daily trivia for 18+ players. Know it, score it."
        static let dailyJackpotTitle = "Today's Round"
        static let dailyJackpotSubtitle = "10 questions · one official run per day."
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

        static let resultsEmptyTitle = "No round to score"
        static let resultsEmptyMessage = "Start from the hub or pick categories to see your results here."
        static let resultsHeadlineDaily = "Round Results"
        static let resultsHeadlinePractice = "Round Results"
        static let triviaEmptyTitle = "Deck's thin right now"
        static let triviaEmptyMessage = "Try different Detroit categories or check back later."
        static let resultsHighScoreMessage = "You knew it — well played."
        static let resultsEncourageMessage = "Close one. Run it back and climb the board."
        static let resultsDailyHighScore = "Strong round — well played."
        static let resultsDailyEncourage = "Tomorrow's deck is fresh. You'll get another shot."
        static let resultsDailyBanner = "Today's round is on the books. See you tomorrow."

        static let highScoreAccuracyThreshold = 70

        static let quickHitEyebrow = "FREE SAMPLE"
        static let quickHitTitle = "If you know, you win"
        static let quickHitSubtitle = "Three quick questions to see how it feels. No account — just play."
        static let quickHitPlayCTA = "Play the Sample"
        static let quickHitSignInPrompt = "I already have an account"
        static let quickHitHighlightDuration = "3 questions · under a minute"
        static let quickHitHighlightNoLogin = "No sign-up to start"
        static let quickHitHighlightCategories = "Real trivia categories"
        static let quickHitResultsTitle = "You showed up."
        static let quickHitResultsTitleStrong = "You knew it."
        static let quickHitResultsCTA = "Lock in today's official round — create a free account and compete on the daily board."
        static let quickHitCreateAccountCTA = "Claim my free account"
        static let quickHitSignInCTA = "Sign in"
        static let firstJackpotTitle = "Your First Round"

        static let hubHeadline = "If you know, you win"
        static let hubGreeting = "One official run a day. Same 10 questions for everyone."
        static let hubDailyEyebrow = "TODAY'S MAIN EVENT"
        static let hubDailyTitle = "Daily Round"
        static let hubDailyCTA = "Play Today's Round"
        static let hubDailySubtitle = "10 questions · once per day."
        static let hubDailyCompletedCTA = "Back tomorrow"
        static let hubDailyCompletedNote = "Daily round locked for today."
        static let hubSecondarySectionTitle = "More ways to play"
        static let hubPickupRoundsTitle = "Pickup Rounds"
        static let hubPickupRoundsSubtitle = "Practice any category — no daily limit."
        static let hubMembersClubTitle = "Members Club"
        static let hubMembersClubSubtitleMember = "18+ lounge deck unlocked"
        static let hubMembersClubSubtitleLocked = "Invite-only · lounge code required"
        static let hubLeaderboardLink = "Today's standings →"
    }
}
