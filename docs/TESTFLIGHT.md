# TestFlight beta checklist — Jackpot Trivia

Use this before inviting real testers. No Supabase required.

## 1. Recommended beta access mode

In the app: **Admin (gear) → Access Settings**

| Setting | TestFlight recommendation |
|---------|---------------------------|
| **Access mode** | **Open (Not Listed)** — testers tap Continue without a code |
| **Allow invite codes** | On (optional codes still work) |
| **Require manual approval** | Off for wide beta; On for small closed group |
| **Member limit** | Set a cap (e.g. 50) if you want to control growth |

Settings **persist on device** after you change them.

## 2. Apple Developer setup

1. [developer.apple.com](https://developer.apple.com) — enroll in Apple Developer Program ($99/year).
2. **App Store Connect** → Apps → **+** → New App.
   - Platform: iOS  
   - Name: Jackpot Trivia  
   - Bundle ID: must match Xcode (`COLEY.JackpotTrivia` or your team’s ID)
3. Fill **App Information**: category (Games / Trivia), age rating questionnaire, privacy policy URL (required for external testers — can use a simple Notion/GitHub page stating demo points, no real cash yet).

## 3. Xcode archive

1. Select **Any iOS Device (arm64)** (not Simulator).
2. **Product → Archive**.
3. **Distribute App** → **App Store Connect** → Upload.
4. Wait for processing in App Store Connect (often 15–60 minutes).

## 4. TestFlight configuration

1. App Store Connect → your app → **TestFlight**.
2. Select the uploaded build → answer **Export Compliance** (typically “No” for custom encryption if you only use HTTPS standard APIs).
3. **Internal testing**: up to 100 team members (immediate).
4. **External testing**: create a group, add emails, submit **Beta App Review** (first external build needs review).

### What to put in “What to Test”

```
• Sign up and play Today's Jackpot (one run per day)
• Practice mode with categories and moods
• Leaderboards (Today / Week / All Time)
• Share score and challenge a friend from Results
• Report a question issue after answering
• Admin → Access Settings (beta access rules)
Note: Points are demo rewards, not real cash.
```

## 5. Pre-flight smoke test (Simulator or device)

- [ ] Sign up / sign in  
- [ ] Play daily jackpot → Results → share  
- [ ] Practice round with 2+ categories  
- [ ] Leaderboard shows your score  
- [ ] Report a question (flag icon)  
- [ ] Admin: change access mode, kill app, reopen — settings stick  
- [ ] Optional: `xcrun simctl openurl booted "jackpottrivia://challenge?from=Test&points=500&accuracy=80&day=2026-05-20"`

## 6. Assets before public TestFlight

- [ ] Replace **App Icon** placeholders in `Assets.xcassets/AppIcon`
- [ ] Confirm **green** brand on launch screen / home
- [ ] Bump **Version** (marketing) and **Build** (integer) each upload

## 7. Known beta limitations (set tester expectations)

- Auth is **on-device** (not synced across devices)
- Leaderboards mix **your scores** with demo names
- **No real money** payouts — wallet is demo
- Supabase optional — not required for TestFlight

## 8. Collect feedback

Ask testers for:

- Confusing screens or copy  
- Questions that feel wrong (use in-app **Report issue**)  
- Crashes (Settings → Privacy → Analytics share if you add a crash reporter later)

Admin → **Question Review** shows flagged IDs and report counts on your device.
