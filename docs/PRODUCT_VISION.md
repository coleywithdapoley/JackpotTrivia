# Product vision (from founder call)

Aligned with the Jackpot Trivia build — update when scope changes.

## Core loop

- **Free public side:** daily jackpot, practice, leaderboards, share/challenge
- **Private lounge (18+):** invite-unlocked mature deck; no in-app cash
- **Live events (future):** real cash prizes at venues — not in-app gambling

## Questions

- **Multiple choice** and **true/false** — pick format per question
- **You and Kwan add questions** via Admin → *Add a question on this device*
- Bundled `QuestionCatalog.json` + on-device custom entries
- Difficulty ramps over time; start approachable for retention

## Invites (pyramid)

| Tier | Role | Can invite |
|------|------|------------|
| 1 | Founder (`TRIVIA2026`, `VIP123`) | Many (50) |
| 2 | Member (invited by founder) | 2 |
| 3 | Leaf (invited by member) | 0 |

Private links expire in **12 hours**, one use each.

## Anti-cheat

- Per-question **timer**
- **Leaving the app** during a timed question → round **forfeited**
- **Replay** same mode → **new shuffle** of questions

## Monetization & prizes

- **v1:** free app, demo points only
- **Later:** membership tiers; cash at **events**, not daily in-app jackpots
- Legal review before any real-money in-app feature

## Design notes

- QuizUp-inspired flow
- **Category-tinted backgrounds** during trivia (sports, science, history, etc.)
- Simple navigation for short attention spans

## Config flags (`AppConfig.swift`)

- `requiresInviteAfterAuth` — `false` for open beta, `true` for code-only launch
- `founderInviteCodes` — tier-1 codes
- `founderReferralLimit` / `tier2ReferralLimit` — invite caps
