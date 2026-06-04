# Jackpot Trivia — Master Prompt (Merged)

Merged from Prompts 1–4 + current codebase audit. Use this as the single source of truth for product critique and implementation.

**Priority note:** Prompt 4 (Open Trivia DB, AI import, macOS Question Builder) is **documented but not a current priority**. Do not start Prompt 4 work until P0 is shipped and the founders explicitly approve. **Stop and ask before beginning any Question Builder / bulk content pipeline work.**

---

## 1. Product snapshot

**Jackpot Trivia** is an **18+ leaning** iOS trivia app (SwiftUI). Target: short, rewarding sessions (QuizUp-inspired), category flavor, daily habit + practice + optional private lounge.

| Principle | Detail |
|-----------|--------|
| v1 economics | Free to download and play. **No in-app cash, payments, sweepstakes, or StoreKit.** |
| Demo rewards | Points are **XP / bragging rights only** — rename “wallet” in UI; explicit “no cash value” copy. |
| Future prizes | Real cash at **live venue events** only — supporting copy, not hero messaging. |
| Audience | 18+; mature topics gated behind membership/lounge — Cards Against Humanity PG-13 tone, not explicit. |
| v1 positioning (Perplexity) | Lead with: *“A fast daily trivia sprint for grown folks, with an invite-only lounge for spicier categories. No bets, no in-app cash.”* |
| Team | Small (2 founders); optional Supabase when configured; otherwise local-first. |

---

## 2. Access model (three independent layers)

Do not conflate these in code or marketing copy.

| Layer | Purpose | Config / gate |
|-------|---------|---------------|
| **App access** | Who may use the app at all when launch is closed | `AppConfig.requireAppAccessCode` + `AppAccessService.hasAppAccess` |
| **Auth** | Account identity | Email/password; local or Supabase |
| **Membership** | Private Lounge + member perks | `MembershipTier` via admin **membership codes** |
| **Premium (future)** | Freemium game limits / ads | `AccessTier` in `Monetization.swift` — **separate from membership** |

**Launch modes:**

- **Open beta:** `requireAppAccessCode = false`, `requiresInviteAfterAuth = false` → sign in → home → daily/practice open; lounge requires membership.
- **Invite-only launch:** `requireAppAccessCode = true` → access code screen → auth → home.

**Evaluation order:** App access → Auth → **first game (warmup)** → Home → Membership (lounge only).

**User-facing copy (Perplexity — simplify to two codes):**

| User sees | Purpose | Internal |
|-----------|---------|----------|
| **Access code to join** | One-time app gate (when enabled) | `AppAccessService` |
| **Lounge code** | Unlock 18+ Private Lounge | `MembershipService` |

Do **not** show pyramid tiers, “Tier 2,” or tree UI. Internally keep `MemberRole` quotas (“You have 2 invites”). Consider **48–72h** invite link expiry early (config); shorten later if abused.

**Social invite pyramid** remains backend-only for quota; challenges are the **primary growth loop**, not invites.

---

## 3. Core loop (mostly built)

### Gameplay

- **Formats:** Multiple choice (4 options) + true/false (`QuestionType`).
- **Categories (today):** General Knowledge, Science, History, Sports, Movies & TV, Music — 61 approved questions in `QuestionCatalog.json`.
- **Discovery-call categories not yet in app:** Economics, Dating/Relationships (founder decision: add vs keep current six).
- **Daily jackpot:** One official run per calendar day; 10 questions; deterministic deck per day (`DailyGameService`).
- **Practice:** Category/mood selection; shuffle questions and answer order.
- **Private Lounge:** 18+ mature-flagged questions; separate round kind.
- **Scoring:** Base + speed + streak (`ScoringEngine`); results screen with share/challenge (Phase 2 — keep).
- **Anti-cheat:** Per-question timer; backgrounding app during timed question **forfeits round**; replay = new shuffle.

### Already shipped (Phase 2–3 — do not rip out)

Auth, daily hub, leaderboards, friend challenges, comfort filters, question reports/stats/review, optional Supabase sync, on-device `AddQuestionView`, invite links, demo wallet, feature gates (free vs premium caps).

Mark these as **shipped / enhance only** unless a P0 task requires touching them.

---

## 4. Gaps to close (priority order)

Priorities below merge **Prompts 1–3** with **Perplexity feedback (§8)**. Prompt 4 remains deferred.

### P0 — Before TestFlight (implement first)

| # | Item | Source |
|---|------|--------|
| 1 | **First-run flow + home hierarchy** — access (if ON) → auth → **5-question warmup** → results → then full hub; demote wallet/lounge/membership on first open | Perplexity #1 |
| 2 | **App access + membership screens** — two clear code flows; hide pyramid UI | P0a/b + Perplexity #2 |
| 3 | **Rename wallet → XP / score bank** + “no cash value” disclaimer in app + store copy | Perplexity #3 |
| 4 | **Jackpot vs practice separation** — zero same-day overlap | P0c + Perplexity #6 |
| 5 | **Lounge behind membership** — clear “Members only” wall + code field | P0b + Perplexity #7 |
| 6 | **Basic progression** — account level, total correct, best streak, 1–2 badges; optional monthly streak shield | Perplexity #5 |
| 7 | **Invite copy cleanup** — “You have N invites”; no MLM language | Perplexity #9 |
| 8 | **Local instrumentation** — log daily start/finish, practice start, lounge attempts (extend `Analytics`) | Perplexity #8 |
| 9 | **README / docs sync** — three access layers + daily/practice split | Perplexity #10 |

#### P0a. App access gate (Prompt 3)

- Models: `AppAccessCode`, `AppAccessService`, `LocalAppAccessService`, `AppAccessAdminService`.
- Config: `AppConfig.requireAppAccessCode` (distinct from `requiresInviteAfterAuth`).
- UI: Access Code screen before auth when gate ON.
- Persistence: device/installation-level `hasAppAccess` (+ optional per-user).
- Root routing in `RootContentView` / `JackpotTriviaApp`.
- Tests: valid/expired/exhausted/inactive codes; flow routing; **independence from membership**.

#### P0b. Membership system (Prompt 2)

- Models: `MembershipTier` (`.free`, `.member`), `MembershipCode`, `MembershipService`, `LocalMembershipService`, `MembershipAdminService`.
- Extend `AuthUser` with `membershipTier`; persist across sessions.
- UI: **“Lounge code”** / Membership screen; redeem with generic errors.
- Gate `PrivateLoungeAccessView` on `.member`; migrate off ad-hoc `PrivateAccessStore` as source of truth.
- Tests: code validation; lounge gating; independence from app access.

#### P0c. Jackpot vs practice separation (Prompt 3)

**Problem:** Today both modes draw from the same pool; practice can repeat today’s jackpot questions.

- Extend catalog/model: `isJackpotEligible`, `isPracticeEligible` (defaults `true` for existing rows).
- Persist: today’s jackpot question IDs by day key; optional `jackpotLastUsedAt` sidecar.
- APIs: `questionsForDailyJackpot(date:)` and `questionsForPractice(..., excludingJackpotForDate:)`.
- Wire `GameSession.beginDailyRound` and practice `beginRound`.
- Tests: zero overlap same date; graceful fallback if catalog too small (log + TODO).

#### P0d. Onboarding warmup (Perplexity — **decided**)

- After first auth, auto-start a **separate 5-question warmup** (General Knowledge or random) before exposing full home.
- Warmup does **not** consume the official daily run and does **not** call `DailyGameService.markDailyCompleted()`.
- Use a distinct `RoundKind` (e.g. `.onboardingWarmup`) so results copy and analytics differ from daily jackpot.
- After warmup results: reveal home with primary CTA “Play Today’s Jackpot” (still available once/day).
- Do not mention lounge or membership codes in the first session.

#### P0e. XP rebrand + disclaimers (Perplexity)

- Rename `PrizeWallet` UI strings → “XP” / “Score bank.”
- Update `AppConfig.Copy.prizeDisclaimer` and App Store-facing strings.
- Keep internal `PrizeWallet` type until a refactor is worth it.

#### P0f. Basic progression (Perplexity — minimal v1)

- XP from daily + challenges → simple **account level**.
- Surface: total correct, best streak, 1–2 badges.
- **Streak shield:** one free miss per calendar month (optional P0 if time tight → P1).

### P1 — Before TestFlight if time; required before App Store

| Item | Notes |
|------|-------|
| **Manual catalog → ~150–200 questions** | ~25–30 per category + lounge adult-safe set; use `AddQuestionView` + JSON — **not** OpenTDB/Question Builder |
| Category list decision | Keep 6 or add 1–2 adult-leaning categories for lounge |
| Push notification hooks | Local scheduling stubs; “Daily is ready” later |
| Daily recap / share screen polish | Screenshot-worthy results |
| Supabase: pick one path for leaderboards | Harden or stay local-only — no half-demo |

### P2 — Deferred / not priority (Prompt 4)

**Do not implement until founders say go.** When P0/P1 are done, **stop and notify the user** before Question Builder / OpenTDB / AI pipeline.

Prompt 4 scope (future): Open TDB, AI import, macOS Question Builder, stats auto-relabel — see §8.

---

## 5. Built vs gap checklist

| Area | Status | Key files |
|------|--------|-----------|
| MCQ + T/F | Built | `QuestionType`, `TriviaQuestion` |
| Catalog (61 Q) | Built | `Resources/QuestionCatalog.json` |
| Shuffle + timer + forfeit | Built | `QuestionBank`, `TriviaQuestionView` |
| Daily jackpot | Built | `DailyGameService`, `DailyJackpotView` |
| On-device add question | Built | `AddQuestionView` |
| Question stats / review | Built | `QuestionStatsStore`, `QuestionReviewView` |
| App access before auth | **Gap** | New services + root routing |
| Membership codes | **Gap** | New services + `MembershipView` |
| Jackpot/practice split | **Gap** | Catalog fields + selection services |
| Question Builder / OpenTDB | **Deferred (P2)** | Not started |
| Real money / StoreKit | Out of scope | — |

---

## 6. Open decisions (founders)

| # | Decision | Status |
|---|----------|--------|
| 1 | Default launch mode | **Decided — config toggle only; default `requireAppAccessCode = false` for TestFlight; founders flip for closed launch** |
| 2 | Warmup vs first daily | **Resolved — separate 5-Q warmup; Today’s Jackpot stays once/day** |
| 3 | Category list | Open — keep 6 + lounge topics manually; defer Economics/Dating rename |
| 4 | Social invite → membership | Open — internal quotas; lounge code = membership redeem |
| 5 | Invite link expiry | Open — start 48–72h, not 12h |
| 6 | Prompt 4 / Question Builder | **Deferred** — manual catalog to 150–200 first |
| 7 | App name “Jackpot” | Open — soften UI copy (XP, not wallet); revisit before App Store |

---

## 7. Out of scope (all prompts)

- In-app cash, sweepstakes, gambling mechanics.
- StoreKit, ad SDK integration (flags only today).
- Runtime AI question generation in the app.
- Full backend CMS.
- Shipping Question Builder to App Store.
- Heavy anti-cheat beyond timer + background forfeit.

---

## 8. Perplexity feedback — summary & adopted decisions

*Received external critique; integrated below. Use this section for founder decisions, not as a prompt to re-run.*

### Product–market fit

- **Verdict:** Strong daily core + 18+ lounge niche; too many v1 ideas (jackpot + lounge + events + invites + membership).
- **Adopt:** Hero = daily trivia sprint + optional adult lounge. Event cash = website/IG, not in-app hero.
- **Adopt:** Soften “jackpot” expectations in UI (XP, disclaimers); name can stay for brand.

### Retention (post-P0)

- Account level + 30-day season badges (Bronze/Silver/Gold).
- One streak shield per month.
- Push hooks later (“Daily is ready,” friend beat score).

### Growth

- **Adopt:** Challenges > invites for growth.
- **Adopt:** Two user-facing codes only (app access + lounge).
- **Adopt:** Hide pyramid tiers in UI; longer invite expiry early.

### Onboarding flow (target)

1. App access code (if enabled) — once per device/account  
2. Auth — subtext: “Invite-only daily trivia for 18+ players”  
3. **5-question warmup** — first question within ~30s  
4. Results → then home hub  
5. Lounge/membership **not** in first session  

### Legal / App Store

- **Adopt:** XP not currency; explicit no-cash-value copy.
- **Adopt:** Lounge = adult topics, not explicit content.
- Legal counsel before any online cash or paid entry.

### Content

- **Adopt:** Manual expansion to **150–200 questions** before scale (quality > API bulk).
- **Reject for now:** OpenTDB, AI pipeline, Question Builder (Prompt 4 deferred).
- Mid-term: stats flag retire/relabel after retention proves out.

### De-scope (confirm)

- Question Builder, OpenTDB, AI integration, complex Supabase beyond auth/leaderboards choice, in-app cash UI, pyramid marketing copy.

### Before TestFlight — ranked (from Perplexity)

1. Simplify first-run + home hierarchy  
2. Clean app access + membership UX  
3. Rename wallet → XP + disclaimers  
4. Manual catalog ~150 questions  
5. Basic progression + badges  
6. Daily vs practice separation  
7. Lounge membership wall  
8. Instrumentation  
9. Invite copy cleanup  
10. README sync  

### Before App Store — ranked (from Perplexity)

1. Harden leaderboards (Supabase or local)  
2. Push notification hooks  
3. Shareable daily recap  
4. Curated lounge content + 18+ gate  
5. One paid Pro tier (stats/practice — no daily advantage)  
6. Light legal review  
7. Tune invite quotas from data  
8. Better analytics  
9. TestFlight UX polish  
10. Store screenshots/copy match experience  

---

---

# TRIM A — Perplexity (paste below this line)

**Context:** I'm building **Jackpot Trivia**, an 18+ leaning iOS trivia app (SwiftUI). Free to play; **no in-app cash or payments**. Demo points only. Future real prizes planned for **live venue events**, not in-app gambling. Small team (2 founders); optional Supabase backend.

**What's built:** Email auth; home hub with **Today's Jackpot** (once/day, 10 questions), practice mode, demo points wallet, local leaderboards, friend challenge deep links, comfort filters, 61-question bundled catalog (MCQ + true/false, easy/medium/hard), per-question timers, forfeit on app background, on-device question authoring, question reports/stats/admin review, optional Supabase for auth/catalog/sync, social invite pyramid (founder → 2 invites → leaf), Private Lounge (18+ mature-flagged questions), freemium feature gates (not StoreKit yet).

**What we're implementing next (P0):**

1. **App access layer** — optional invite-only gate *before* auth (`requireAppAccessCode`), separate from login.
2. **Membership layer** — admin-issued codes upgrade user to `.member`; gates Private Lounge (not payments).
3. **Jackpot vs practice split** — today's daily questions must not appear in practice the same day.

**Explicitly NOT doing now:** macOS Question Builder, Open Trivia DB bulk import, AI content pipeline (documented for later only).

**Access model (three layers):** (1) App access code → can use app; (2) Auth account; (3) Membership code → Private Lounge. Plus separate future "premium" tier for game limits/ads. Social invite pyramid exists for growth — may overlap with membership; we're simplifying messaging.

**Content today:** 6 categories, 61 human-verified questions. Discovery call also mentioned Economics and Dating categories — not added yet.

**Tensions to critique:**

- Is "Jackpot" branding confusing with demo-only points?
- Three access layers + social invites — too confusing for onboarding?
- 61 questions with 10/day daily + practice separation — enough for retention pre-scale?
- 18+ lounge with mild placeholder content — enough differentiation?
- Split: public daily habit vs private lounge vs future event cash — coherent positioning?
- vs Wordle-style dailies, HQ trivia successors, Kahoot, generic trivia apps — what would stand out in 2026?

**Please provide:**

1. Product-market fit and positioning critique (be skeptical).
2. Retention and habit mechanics — what's missing for a daily trivia app?
3. Growth loops — invite pyramid + membership codes + challenges — viral enough or fatigue risk?
4. UX/onboarding — recommended first-session flow given three access layers.
5. Legal/App Store — "Jackpot" name, demo points, 18+ gated lounge, future event prizes.
6. Content strategy at small scale (manual curation vs deferring bulk import).
7. **Ranked top 10 improvements** before TestFlight vs before public App Store launch.
8. What we should **stop doing** or de-scope to ship faster.

Assume limited budget; Supabase optional; no real-money features in v1.

---

---

# TRIM B — Cursor implementation (paste below this line)

You are a senior Swift/iOS engineer working on **JackpotTrivia** (SwiftUI). Implement **P0** per `docs/MASTER_PROMPT.md` (including Perplexity §8). Do **not** start Prompt 4 (Question Builder, OpenTDB, AI import) or bulk catalog automation — if you finish P0, **stop and tell the user** before content-pipeline or 150-question bulk work unless they explicitly ask.

## Constraints

- No payments, StoreKit, real money, or runtime AI.
- Reuse existing patterns: `LocalAuthService`, `InviteLinkService`, `DailyGameService`, `UserDefaults`, `Analytics`.
- Keep `AccessTier` (freemium caps) separate from `MembershipTier` (lounge).
- User-facing: only **two codes** — “Access code to join” and “Lounge code” — no pyramid tier UI.
- Keep stable `catalogID` slugs in `QuestionCatalog.json`.
- Minimal diffs; unit tests for new logic.

## P0 worklist (order)

### P0a — App access gate
(create `AppAccessCode`, `AppAccessService`, `LocalAppAccessService`, `AppAccessAdminService`, `AppAccessCodeView`, tests; edit `AppConfig`, root routing)

### P0b — Membership / lounge gate
(create `MembershipTier`, `MembershipCode`, `MembershipService`, `MembershipView`, tests; edit `AuthUser`, `PrivateLoungeAccessView`)

### P0c — Jackpot vs practice separation
(edit `QuestionCatalogDTO`, `TriviaQuestion`, `DailyGameService`, `QuestionBank`, `GameSession`, tests)

### P0d — Onboarding warmup (**decided: separate from daily**)

After first signup/login for a user who has not completed warmup: auto 5-question round (`RoundKind.onboardingWarmup`) before full `DailyJackpotView`. Does not mark daily complete. Then reveal home. No lounge/membership in first session.

### P0e — XP rebrand
Rename wallet UI → “XP” / “Score bank”; strengthen `AppConfig.Copy.prizeDisclaimer` (“no cash value”).

### P0f — Basic progression (minimal)
Simple level from XP, total correct, best streak on profile/home; optional streak shield → P1 if tight.

### P0g — Copy + analytics
Simplify invite strings (“You have N invites”); log daily start/finish, practice start, lounge blocked events.

## Explicit non-goals

- QuestionBuilder, OpenTDB, AI import
- Manual 150-question catalog expansion (founder content task unless asked)
- Supabase beyond stubs
- StoreKit / ads
- Pyramid tier UI

## When P0 complete

Report status and **ask the user** before Prompt 4, Question Builder, or large catalog pushes.
