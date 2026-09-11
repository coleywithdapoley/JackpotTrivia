-- Phase 5: Admin add / retire questions for every player
-- Adds: founder allowlist, shared retire list, write policies, Detroit categories.

create table if not exists public.app_admins (
  email text primary key
);

insert into public.app_admins (email)
values ('admin@ifyouknowyouwin.app')
on conflict (email) do nothing;

alter table public.app_admins enable row level security;

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.app_admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

revoke all on function public.is_app_admin() from public;
grant execute on function public.is_app_admin() to authenticated;

create table if not exists public.catalog_retired_slugs (
  catalog_slug text primary key,
  retired_at timestamptz not null default now(),
  retired_by uuid references public.profiles (id) on delete set null
);

alter table public.catalog_retired_slugs enable row level security;

drop policy if exists catalog_retired_read on public.catalog_retired_slugs;
create policy catalog_retired_read on public.catalog_retired_slugs
  for select to authenticated
  using (true);

drop policy if exists catalog_retired_admin_insert on public.catalog_retired_slugs;
create policy catalog_retired_admin_insert on public.catalog_retired_slugs
  for insert to authenticated
  with check (public.is_app_admin());

drop policy if exists catalog_retired_admin_delete on public.catalog_retired_slugs;
create policy catalog_retired_admin_delete on public.catalog_retired_slugs
  for delete to authenticated
  using (public.is_app_admin());

grant select, insert, delete on public.catalog_retired_slugs to authenticated;

drop policy if exists questions_admin_insert on public.questions;
create policy questions_admin_insert on public.questions
  for insert to authenticated
  with check (public.is_app_admin());

drop policy if exists questions_admin_update on public.questions;
create policy questions_admin_update on public.questions
  for update to authenticated
  using (public.is_app_admin())
  with check (public.is_app_admin());

drop policy if exists question_answers_admin_insert on public.question_answers;
create policy question_answers_admin_insert on public.question_answers
  for insert to authenticated
  with check (public.is_app_admin());

drop policy if exists question_answers_admin_delete on public.question_answers;
create policy question_answers_admin_delete on public.question_answers
  for delete to authenticated
  using (public.is_app_admin());

drop policy if exists categories_admin_insert on public.categories;
create policy categories_admin_insert on public.categories
  for insert to authenticated
  with check (public.is_app_admin());

grant select, insert, update on public.questions to authenticated;
grant select, insert, delete on public.question_answers to authenticated;
grant select, insert on public.categories to authenticated;

insert into public.categories (name, emoji, sort_order)
values
  ('Motown & Music', '🎵', 1),
  ('Detroit Sports', '🏈', 2),
  ('Auto City', '🚗', 3),
  ('Local Legends', '⭐', 4),
  ('Downtown & Neighborhoods', '🏙️', 5)
on conflict (name) do nothing;
