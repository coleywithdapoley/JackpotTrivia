# TestFlight — external testers

Use this for a public or friends-and-family **external** group. Internal team testing can skip the privacy URL and Beta App Review.

Display name on the home screen: **If You Know, You Win**. Bundle ID: `COLEY.JackpotTrivia`. Version **1.0**, build **1**. Testers need **iOS 26**.

## What is true in this build

- Free to play. **No in-app purchases.** Premium is not for sale.
- XP / points are **bragging rights only** — no cash, no sweepstakes.
- Accounts and standings go through **Supabase**. Testers must **create a new account** in this build. Old on-device logins will not appear on the shared board.
- App access code is **off** (`requireAppAccessCode = false`). Lounge membership is separate and optional.
- Archive **on the Mac that has** `JackpotTrivia/Config/SupabaseSecrets.plist`. That file is gitignored; a machine without it ships local-only accounts.

Do **not** send testers the admin password. Admin is `admin@ifyouknowyouwin.app` for founders only.

## 1. Host the privacy policy (required for external)

Apple will reject the external group without a public **Privacy Policy URL**.

1. Commit and push `docs/PRIVACY.md`.
2. Paste one of these into App Store Connect → App Information → Privacy Policy URL:
   - GitHub: `https://github.com/coleywithdapoley/JackpotTrivia/blob/main/docs/PRIVACY.md`
   - Or copy the same text into a public Notion page if GitHub asks reviewers to sign in.

Contact email in that policy: **cobb.cole@gmail.com**.

## 2. App Store Connect app record (once)

1. [App Store Connect](https://appstoreconnect.apple.com) → Apps → **+** → New App.
2. Platform: iOS. Bundle ID: `COLEY.JackpotTrivia`.
3. Store name can differ from the home-screen name.
4. Category: **Games → Trivia**.
5. Age rating questionnaire: **17+** (Private Lounge is mature / 18+ leaning).
6. App Privacy (nutrition labels) — match the privacy manifest:
   - Email Address, Name, User ID, Gameplay Content, Other User Content
   - Linked to identity: **Yes**
   - Used for tracking: **No**
   - Purpose: App Functionality
7. Export compliance: **No** (standard HTTPS only). `ITSAppUsesNonExemptEncryption` is already `false` in Info.plist.

## 3. Archive and upload

1. Open the project on **this Mac** so `SupabaseSecrets.plist` is in the target.
2. Scheme: JackpotTrivia. Destination: **Any iOS Device (arm64)**.
3. **Product → Archive** → **Distribute App** → App Store Connect → Upload.
4. Wait until the build appears under TestFlight (often 15–60 minutes). Processing must finish before you can submit for Beta App Review.

If you already uploaded build **1**, bump `CURRENT_PROJECT_VERSION` before the next archive.

## 4. External group + Beta App Review

1. TestFlight → **External Testing** → create a group (e.g. “Friends”).
2. Add the processed build to that group.
3. Fill **What to Test** with the copy below — **do not** mention Admin, gear, or access settings.
4. **Beta App Review Information:**
   - Sign-in required: **Yes**
   - Create a throwaway account in the live app (e.g. `reviewer@ifyouknowyouwin.app`) and put **that** email/password only in App Store Connect, not in tester emails.
   - Notes: “No in-app purchases. Points have no cash value. Optional Private Lounge is members-only and 17+.”
5. Submit for **Beta App Review**. First external build usually takes 24–48 hours. After approval, testers get email invites.

### What to Test (paste this)

```
Thanks for trying If You Know, You Win — Detroit trivia, no cash prizes.

Need iOS 26. Create a new account in the app (old logins will not work).

Please try:
• Play the 3-question sample, then create an account
• Finish Today's Jackpot (one official run per day)
• Play a practice round with 1–2 Detroit categories
• Open Standings (Today / Week / All Time) and confirm your name appears
• Share a score or challenge a friend from Results
• Report a question after answering if something feels off

Notes:
• Points and XP have no cash value
• There is nothing to buy in this beta
• Private Lounge is optional and intended for 17+
```

## 5. Invite testers

- Email invites from the external group, or a public TestFlight link after the group is approved.
- Cap the group if you want a small friends list (Apple allows up to 10,000 external testers).
- Tell them: **iOS 26**, new sign-up, no real money, lounge is optional.

## 6. Smoke test on a device before you submit

- [ ] Guest sample (3 questions) → create account
- [ ] First official round → Results → standings show your name
- [ ] Practice with two categories
- [ ] No crown / “Unlock Premium” / buy button anywhere a player can tap
- [ ] Report a question
- [ ] Kill and reopen — still signed in

## 7. Known limits to set in tester email (optional)

- iOS 26 only
- New account required for this backend
- Practice is capped at two categories in this beta
- Standings need a network connection
- Private Lounge needs a lounge code from the founders
