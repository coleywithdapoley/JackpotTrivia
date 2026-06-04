-- Jackpot Trivia — Phase 3: run after phase1 + phase2 migrations
-- Applies RLS, profile trigger, seed helpers, and stats RPC by catalog_slug.

-- ---------------------------------------------------------------------------
-- Profiles on signup
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do update
    set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Stats upsert by catalog slug (client flywheel sync)
-- ---------------------------------------------------------------------------
create or replace function public.upsert_question_stats_by_slug(
  p_catalog_slug text,
  p_play_date date,
  p_times_shown int default 0,
  p_times_correct int default 0,
  p_times_incorrect int default 0,
  p_times_timed_out int default 0,
  p_report_count int default 0
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_question_id uuid;
begin
  select id into v_question_id
  from public.questions
  where catalog_slug = p_catalog_slug
  limit 1;

  if v_question_id is null then
    return;
  end if;

  insert into public.question_stats_daily (
    question_id,
    play_date,
    times_shown,
    times_correct,
    times_incorrect,
    times_timed_out,
    report_count
  )
  values (
    v_question_id,
    p_play_date,
    p_times_shown,
    p_times_correct,
    p_times_incorrect,
    p_times_timed_out,
    p_report_count
  )
  on conflict (question_id, play_date) do update
    set times_shown = question_stats_daily.times_shown + excluded.times_shown,
        times_correct = question_stats_daily.times_correct + excluded.times_correct,
        times_incorrect = question_stats_daily.times_incorrect + excluded.times_incorrect,
        times_timed_out = question_stats_daily.times_timed_out + excluded.times_timed_out,
        report_count = question_stats_daily.report_count + excluded.report_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security (adjust for your auth model)
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.question_answers enable row level security;
alter table public.categories enable row level security;
alter table public.daily_games enable row level security;
alter table public.daily_game_questions enable row level security;
alter table public.leaderboard_scores enable row level security;
alter table public.question_reports enable row level security;
alter table public.daily_completions enable row level security;
alter table public.game_rounds enable row level security;

-- Profiles: users read/update own row
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id);

-- Approved questions readable by authenticated users
create policy questions_read_approved on public.questions
  for select to authenticated
  using (status = 'approved' and is_active = true);

create policy question_answers_read on public.question_answers
  for select to authenticated
  using (
    exists (
      select 1 from public.questions q
      where q.id = question_id and q.status = 'approved' and q.is_active = true
    )
  );

create policy categories_read on public.categories
  for select to authenticated
  using (is_active = true);

create policy daily_games_read on public.daily_games
  for select to authenticated
  using (true);

create policy daily_game_questions_read on public.daily_game_questions
  for select to authenticated
  using (true);

-- Leaderboards: read all scores; insert own
create policy leaderboard_read on public.leaderboard_scores
  for select to authenticated
  using (true);

create policy leaderboard_insert_own on public.leaderboard_scores
  for insert to authenticated
  with check (auth.uid() = user_id);

-- Reports: insert own; admins use service role in dashboard
create policy question_reports_insert on public.question_reports
  for insert to authenticated
  with check (user_id is null or auth.uid() = user_id);

create policy question_reports_read_own on public.question_reports
  for select to authenticated
  using (user_id is null or auth.uid() = user_id);

-- Daily completion: read/insert own
create policy daily_completions_own on public.daily_completions
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Game rounds: insert/read own
create policy game_rounds_own on public.game_rounds
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- RPC for stats
grant execute on function public.upsert_question_stats_by_slug to authenticated;
