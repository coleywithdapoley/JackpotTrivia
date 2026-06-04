-- Jackpot Trivia — Phase 1 reference schema (Supabase / Postgres)
-- Aligns with client models: auth, daily games, questions, scoring, wallet.

-- USERS (extends Supabase auth.users)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text,
  phone_number text,
  access_tier text not null default 'free',
  points_balance int not null default 0,
  lifetime_points int not null default 0,
  created_at timestamptz not null default now()
);

-- QUESTION CATALOG
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  emoji text,
  description text,
  sort_order int not null default 0,
  is_active boolean not null default true
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories (id),
  question_text text not null,
  question_type text not null default 'multipleChoice',
  difficulty text not null default 'medium',
  time_limit_seconds int,
  correct_answer_index smallint not null,
  allows_mature_topics boolean not null default false,
  is_educational boolean not null default true,
  is_family_safe boolean not null default true,
  is_active boolean not null default true
);

create table public.question_answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions (id) on delete cascade,
  sort_index smallint not null,
  answer_text text not null,
  unique (question_id, sort_index)
);

-- DAILY OFFICIAL DECK
create table public.daily_games (
  id uuid primary key default gen_random_uuid(),
  play_date date not null unique,
  title text not null default 'Daily Jackpot',
  question_count int not null default 10,
  published_at timestamptz not null default now()
);

create table public.daily_game_questions (
  daily_game_id uuid not null references public.daily_games (id) on delete cascade,
  question_id uuid not null references public.questions (id),
  sequence_index int not null,
  primary key (daily_game_id, sequence_index)
);

-- GAMEPLAY
create table public.game_rounds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  round_kind text not null default 'practice',
  play_mode text,
  mood text,
  total_questions int not null,
  correct_answers int not null default 0,
  round_points int not null default 0,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.daily_completions (
  user_id uuid not null references public.profiles (id),
  play_date date not null,
  round_id uuid references public.game_rounds (id),
  points_earned int not null default 0,
  primary key (user_id, play_date)
);

-- INVITES (from InviteLinkService)
create table public.invite_links (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  redemption_count int not null default 0,
  max_redemptions int not null default 1
);
