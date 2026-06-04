-- Question quality flywheel (extends phase1_schema.sql)

alter table public.questions
  add column if not exists status text not null default 'approved',
  add column if not exists source text,
  add column if not exists verified_at timestamptz,
  add column if not exists catalog_slug text unique;

create table if not exists public.question_reports (
  id uuid primary key default gen_random_uuid(),
  question_id uuid references public.questions (id) on delete cascade,
  catalog_slug text,
  user_id uuid references public.profiles (id),
  reason text not null,
  reported_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists public.question_stats_daily (
  question_id uuid not null references public.questions (id) on delete cascade,
  play_date date not null,
  times_shown int not null default 0,
  times_correct int not null default 0,
  times_incorrect int not null default 0,
  times_timed_out int not null default 0,
  report_count int not null default 0,
  primary key (question_id, play_date)
);
