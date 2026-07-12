-- Moderation: per-user block list.
--
-- Satisfies Apple App Store Guideline 1.2 (user-generated content): members
-- can block abusive users so they no longer see their messages. Reporting is
-- handled by the existing public.reports table (reporter-scoped RLS).

create table if not exists public.blocked_users (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.blocked_users enable row level security;

-- A user can only see and manage their own block list.
drop policy if exists blocked_users_self on public.blocked_users;
create policy blocked_users_self on public.blocked_users
  for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create index if not exists blocked_users_blocker_idx
  on public.blocked_users (blocker_id);
