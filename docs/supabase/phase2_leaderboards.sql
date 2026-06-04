-- Phase 2: Leaderboards & social (extends phase1_schema.sql)

create table public.leaderboard_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  display_name text not null,
  points int not null,
  correct_answers int not null,
  total_questions int not null,
  round_kind text not null,
  play_date date not null default (current_date),
  recorded_at timestamptz not null default now()
);

create index leaderboard_scores_daily_idx
  on public.leaderboard_scores (play_date, points desc);

create index leaderboard_scores_user_idx
  on public.leaderboard_scores (user_id, recorded_at desc);

-- Materialized view optional for weekly/all-time rollups
create table public.friend_challenges (
  id uuid primary key default gen_random_uuid(),
  challenger_id uuid not null references public.profiles (id),
  challenger_name text not null,
  points int not null,
  accuracy_percent int not null,
  day_key text not null,
  token text not null unique,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
