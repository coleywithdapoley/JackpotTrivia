# Phase 3 — Supabase backend setup

The iOS app uses **Supabase REST + GoTrue** when `SupabaseSecrets.plist` is present. Without it, the app keeps Phase 1–2 local behavior (bundled catalog, `LocalAuthService`, UserDefaults leaderboards).

## 1. Create a Supabase project

1. [supabase.com](https://supabase.com) → New project  
2. Note **Project URL** and **anon public** key (Settings → API)

## 2. Run migrations (SQL editor, in order)

1. `docs/supabase/phase1_schema.sql`
2. `docs/supabase/phase2_leaderboards.sql`
3. `docs/supabase/phase2_question_quality.sql`
4. `docs/supabase/phase3_complete.sql`
5. `docs/supabase/phase4_live_leaderboard.sql`
6. `docs/supabase/phase5_shared_catalog.sql`

## 3. Seed categories & questions

Import your catalog slugs from `JackpotTrivia/Resources/QuestionCatalog.json`:

- Insert rows into `categories` matching `AppConfig.defaultCategories`
- Insert `questions` with `catalog_slug` = JSON `id`, `status` = `approved`, `is_active` = true
- Insert `question_answers` with `sort_index` 0…n

Optional: create `daily_games` + `daily_game_questions` for a fixed official deck per `play_date`.

## 4. Configure the iOS app

```bash
cp JackpotTrivia/Config/SupabaseSecrets.example.plist JackpotTrivia/Config/SupabaseSecrets.plist
```

Edit `SupabaseSecrets.plist`:

| Key | Value |
|-----|--------|
| `SUPABASE_URL` | `https://YOUR_PROJECT.supabase.co` |
| `SUPABASE_ANON_KEY` | Your anon key |

Add `SupabaseSecrets.plist` to the app target (File → Add Files). **Do not commit** real keys — keep the example plist in git only.

## 5. Enable Email auth

Authentication → Providers → Email: enabled.  
For SMS reset, configure a phone provider later; the app still calls the API but SMS is optional.

## 6. Verify in the app

1. Build & run with secrets configured  
2. Sign up / sign in — profile row should appear in `profiles`  
3. Admin → Access Settings → **Backend** section should show “Connected”  
4. Play a round — check `leaderboard_scores`, `game_rounds`, and `question_reports` after reporting a question

## What syncs automatically

| Client data | Supabase table / RPC |
|-------------|----------------------|
| Sign in / up | `auth.users` + `profiles` |
| Remote catalog | `questions` + `question_answers` + `categories` |
| Official daily deck | `daily_games` + `daily_game_questions` |
| Round finish | `leaderboard_scores`, `game_rounds`, `daily_completions` |
| Leaderboard screen | **Reads** `leaderboard_scores` (best score per player) |
| Question reports | `question_reports` |
| Per-question stats | `upsert_question_stats_by_slug` RPC |

Failed syncs are queued in UserDefaults and retried on next launch.
