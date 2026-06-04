# Jackpot Trivia

Daily trivia iOS app built with SwiftUI. Sign in, complete a one-time warmup, play **Today's Jackpot** once per day, practice without limits, and unlock the **Private Lounge** with a membership code. Demo XP has no cash value.

## Access model (three layers)

| Layer | Purpose | Config / service |
|-------|---------|------------------|
| **App access** | Optional closed launch gate before sign-in | `AppConfig.requireAppAccessCode` + `LocalAppAccessService` |
| **Auth** | Email/password account | `AuthManager` / Supabase optional |
| **Membership** | Private Lounge (18+ deck) | `MembershipTier` + `LocalMembershipService` |

**Launch modes:** Set `requireAppAccessCode = false` (default) for open TestFlight beta. Flip to `true` for invite-only launch. Membership is separate — lounge codes do not grant app access.

**First run:** App access (if ON) → sign in → **5-question warmup** (`RoundKind.onboardingWarmup`) → home hub. Warmup does not consume the daily jackpot.

## Daily jackpot vs practice

- **Today's Jackpot:** One official 10-question run per calendar day (`DailyGameService`, cached deck).
- **Practice:** Unlimited category/mood rounds; **excludes today's jackpot question IDs** so you won't see the same questions twice in one day.
- Catalog fields: `isJackpotEligible`, `isPracticeEligible` (default `true`).

## Tech stack

- **Swift + SwiftUI** (iOS)
- **UserDefaults persistence** — access codes, membership, daily completion, XP/progress, invite links
- **Bundled catalog** — `Resources/QuestionCatalog.json` + optional Supabase sync

## How to configure for client

### Brand & naming

Edit **`JackpotTrivia/Config/AppConfig.swift`**:

| Setting | Property |
|--------|----------|
| App title on invite screen | `appDisplayName` |
| Primary accent color | `primaryAccentColor` |
| Tagline, invite labels, results copy | `AppConfig.Copy` |

`DesignSystem.swift` reads the accent from `AppConfig` via `AppColors.royalBlue`.

### Invites & access codes

In **`AppConfig.swift`**:

- `requireAppAccessCode` — show app access screen before auth (default `false`)
- `requiresInviteAfterAuth` — legacy post-auth invite gate (default `false`)
- `defaultInviteCodes` — founder/legacy invite whitelist
- Default app access seeds: `JOIN2026`, `BETA2026` (admin can create more)
- Default lounge codes: `LOUNGE2026`, `MEMBER2026`

Runtime admin: **Admin Access Settings** (gear on home) — app access codes, membership codes, invite links.

### Categories & questions

**Categories**

- Names: `AppConfig.defaultCategories`
- Emoji & blurbs: `AppConfig.categoryEmoji` and `AppConfig.categoryDescriptions`
- UI list is built in `CategorySelectionView` from those values

**Questions**

- Edit sample Q&A in **`JackpotTrivia/Services/QuestionBank.swift`**
- Each question’s `category` string must match a name in `AppConfig.defaultCategories`

## Main types

| Type | Role |
|------|------|
| `AppConfig` | Client-facing constants (brand, invites, categories, copy) |
| `AppAccessService` / `MembershipService` | App access + lounge membership codes |
| `GameSession` | Selected categories, round kind, score, progress |
| `DailyGameService` | Once-per-day jackpot + deck caching |
| `QuestionBank` | Filter by category; practice excludes today's jackpot IDs |
| `AppAccessCodeView` | Pre-auth access code gate |
| `MembershipView` | Lounge code redemption |
| `DailyJackpotView` | Home hub — XP bank, daily, practice, lounge |
| `PrivateLoungeAccessView` | Members-only 18+ deck |
| `CategorySelectionView` | Multi-select categories, start practice |
| `TriviaQuestionView` | One question at a time, scoring |
| `ResultsView` | Score summary and next actions |
| `AdminAccessSettingsView` | Access codes, membership, invites |
| `RootContentView` | Full app flow routing |

## Unit tests

Target: **`JackpotTriviaTests`** (XCTest)

- `AppAccessServiceTests` — app access code validation
- `MembershipServiceTests` — lounge membership codes
- `DailyJackpotPracticeSeparationTests` — zero same-day overlap
- `AccessControlTests` — invite validation, capacity, access mode
- `QuestionBankTests` — category filter, fallback, shuffle helpers
- `GameSessionTests` — score, round setup, reset

In Xcode: **Product → Test** (⌘U), or open the Test navigator and run individual classes.

## Founder call features (client)

- **Invite links:** Shareable links with quotas ("You have N invites"); 72h expiry — `InviteLinkService`
- **Private Lounge:** 18+ member deck — requires `MembershipTier.member`
- **Add questions on device:** Admin → *Add a question on this device*
- **Anti-cheat:** Leaving app during a timed question forfeits the round
- **Category backgrounds:** Tinted trivia backdrop per category (`CategoryTheme`)
- **Vision doc:** `docs/PRODUCT_VISION.md`

## TestFlight beta (no Supabase)

- **Guide:** `docs/TESTFLIGHT.md`
- **Access settings persist** on device (`AccessControlStore`)
- **Beta tip:** Admin → set **Open (Not Listed)** so testers can tap Continue without codes
- **Manual approval:** optional queue in Admin → Pending join requests
- **Catalog:** 60 approved questions in `QuestionCatalog.json` (v4)

## Phase 3 (Supabase backend)

- **Remote auth:** `SupabaseAuthService` when `JackpotTrivia/Config/SupabaseSecrets.plist` is present; otherwise `LocalAuthService`
- **Remote catalog:** `QuestionRepository` fetches approved questions; merges with bundled JSON
- **Official daily deck:** `daily_games` + `daily_game_questions` when seeded server-side
- **Sync:** Rounds, leaderboards, reports, and stats queue to Supabase (`SupabaseSyncService`)
- **Setup:** `docs/supabase/PHASE3_SETUP.md` and `docs/supabase/phase3_complete.sql`

Copy `JackpotTrivia/Config/SupabaseSecrets.example.plist` → `SupabaseSecrets.plist` (gitignored) and add to the app target.

## Question quality flywheel

- **Stable IDs** in `QuestionCatalog.json` (`id`, `status`, `source`, `verifiedAt`)
- **Per-question stats** — `QuestionStatsStore` (miss rate, timeouts)
- **Report issue** on trivia screen → `QuestionReportStore`
- **Admin → Question Review** — flagged questions, local retire, mark reviewed
- **Standards:** `docs/QUESTION_STANDARDS.md`
- **Validation:** `QuestionCatalogValidationTests` + `QuestionCatalogValidator`

## Phase 2 (leaderboards + social + catalog)

- **Leaderboards:** Today / This Week / All Time (`LeaderboardView`) with your rank highlighted
- **Social:** Share score from Results (`ShareLink`); **Challenge a friend** deep link (`jackpottrivia://challenge?...`)
- **Incoming challenges:** Banner on Home when a friend’s link is opened
- **Question catalog:** `Resources/QuestionCatalog.json` (24+ MCQ & true/false) — admin shows catalog stats
- **Backend reference:** `docs/supabase/phase2_leaderboards.sql`

**Try challenge links in Simulator:**  
`xcrun simctl openurl booted "jackpottrivia://challenge?from=Alex&points=1200&accuracy=90&day=2026-05-27"`

## Phase 1 (daily jackpot + rewards — client)

- **Brand:** Green & white (`AppConfig.primaryAccentColor`)
- **Auth:** Email/password sign-in, sign-up, forgot password (email + SMS) — `LocalAuthService` mock until Supabase
- **Home:** `DailyJackpotView` — XP score bank, **Play Today's Jackpot** (once per day), practice mode
- **Questions:** Multiple choice + true/false, **difficulty tiers**, **per-question timers**
- **Scoring:** Base points + speed bonus + streak bonus (`ScoringEngine`)
- **Rewards:** Demo XP score bank (`PrizeWallet`) — no cash value; see `AppConfig.Copy.prizeDisclaimer`
- **Backend reference:** `docs/supabase/phase1_schema.sql`

**Try it:** Create an account on launch → Home → Play Today's Jackpot.

Reset daily completion (Simulator): delete app or clear `jackpotTrivia.daily.lastCompletedDate` in UserDefaults.

## Client features (v1 — local only)

- **Two session types:** Pick Categories vs **Party Mode** (all categories).
- **Mood-based trivia:** Presets auto-select categories; Custom mood = manual category pick.
- **Comfort filters:** Mature / family-safe / educational + age band (`ComfortPreferencesView`).
- **Private invites:** 72h links, referral quotas per member (`InviteLinkService`).
- **Admin:** Create invite links under Access Settings.

Backend still needed for real universal links, anti-abuse, and synced admin dashboard.

## Monetization (feature gates, no StoreKit)

- `AccessTier` (`.free` / `.premium`) and `FeatureGates` in `Services/Monetization.swift`.
- Default tier: `AppConfig.defaultAccessTier` (set to `.premium` for full-access testing).
- Injected via `@Environment(\.featureGates)` from `RootContentView`.
- Gates: max categories per round, max questions per game, `showsAds` placeholder flag.
- TODO markers for StoreKit 2 entitlement checks and paywall presentation.

## Analytics

- Type-safe `AnalyticsEvent` + `AnalyticsTracking` protocol in `Services/Analytics.swift`.
- `ConsoleAnalyticsService` logs to Xcode console in **DEBUG** only (`[Analytics] …`).
- Injected via `@Environment(\.analytics)` from `RootContentView`.
- Swap `ConsoleAnalyticsService` for a Firebase/PostHog type that implements `AnalyticsTracking` and maps `AnalyticsEvent` → provider events.

## Accessibility & localization

- VoiceOver labels, hints, and grouped elements on invite, categories, trivia, results, and admin screens.
- Dynamic Type via semantic fonts (`.largeTitle`, `.body`, `.footnote`, etc.) in `DesignSystem` modifiers.
- Touch targets use `AppMetrics.minimumTouchTarget` (44pt) on fields, cards, and buttons.
- User-facing copy uses `Text("…")` string literals in views so Xcode can extract a **String Catalog** later (Product → Export Localizations).

## App icon, launch screen, and display name

| What | Where to change |
|------|-----------------|
| Name under icon | `JackpotTrivia/Info.plist` → `CFBundleDisplayName`, or target **Info** → *Bundle display name* |
| In-app title | `AppConfig.appDisplayName` / `AppBranding.bundleDisplayName` |
| App icon | `Assets.xcassets` → **AppIcon** (replace 1024×1024 placeholders; see `AppIcon.appiconset/README.txt`) |
| Launch screen | `LaunchScreen.storyboard` + `LaunchBackground` / `BrandRoyalBlue` colors in Assets |

Build settings (already set): `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`, `UILaunchStoryboardName` via Info.plist.

## Running the app

1. Open `JackpotTrivia.xcodeproj` in Xcode.
2. Select an iPhone simulator or device.
3. Run (⌘R).

**Sample codes** (from `AppConfig` / admin seeds): app access `JOIN2026`, `BETA2026`; lounge `LOUNGE2026`, `MEMBER2026`; legacy invites `TRIVIA2026`, `VIP123`

## Future work (optional)

- **Backend invites** — Replace `AccessControl.validInviteCodes` with API validation in `InviteCodeValidator` / `InviteAccessView`.
- **Remote questions** — Load `QuestionBank.allQuestions` from CDN or API; keep category names aligned with `AppConfig.defaultCategories`.
- **Persistence** — Save admin settings and user progress via UserDefaults or your backend; inject into `GameSession` / `AccessControl` at launch.
- **Member cap enforcement** — Count joins against `AccessControl.maxMembers` when real accounts exist.
