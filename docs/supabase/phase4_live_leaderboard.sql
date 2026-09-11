-- Phase 4: Live shared leaderboard
-- Allows every player to read posted scores (insert is still own-row only).

drop policy if exists leaderboard_read on public.leaderboard_scores;
drop policy if exists leaderboard_read_public on public.leaderboard_scores;

create policy leaderboard_read_public on public.leaderboard_scores
  for select
  using (true);
