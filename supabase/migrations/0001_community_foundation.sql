-- ActivHealth community backend — foundation
-- Lives in its OWN Supabase project (isolated from dittopix-prod), in the
-- shared org so billing/ops are shared but health + location data are not.
--
-- Geo policy: the app captures precise GPS on-device for "near me" distance,
-- but only ever STORES and SHARES a coarse point (postcode-district centroid
-- or rounded location). PostGIS geography(Point) holds that coarse point.
--
-- Everything is behind Row Level Security. Helper functions centralise the
-- membership/role checks so policies stay readable.

-- ── Extensions ────────────────────────────────────────────────────────────
create extension if not exists postgis;

-- ── profiles ──────────────────────────────────────────────────────────────
-- One row per auth user. area_point is the COARSE location only.
create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  display_name    text not null default '',
  avatar_url      text,
  outward_postcode text,                       -- e.g. 'WD17' (district only)
  area_point      geography(Point, 4326),      -- coarse centroid, never exact
  visibility      text not null default 'hidden'
                    check (visibility in ('hidden', 'groups_only', 'discoverable')),
  is_pro          boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index profiles_area_gix on public.profiles using gist (area_point);

-- ── sport_ratings ─────────────────────────────────────────────────────────
create table public.sport_ratings (
  profile_id     uuid not null references public.profiles (id) on delete cascade,
  sport          text not null,
  rating_band    text not null default 'all',  -- e.g. '3.0-3.5' (pickleball)
  numeric_rating numeric,                       -- DUPR-style, future
  verified       boolean not null default false,
  primary key (profile_id, sport)
);

-- ── venues ────────────────────────────────────────────────────────────────
create table public.venues (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  outward_postcode text,
  point            geography(Point, 4326),
  indoor           boolean,
  court_count      int,
  booking_url      text,
  price_note       text,
  created_by       uuid references public.profiles (id) on delete set null,
  created_at       timestamptz not null default now()
);
create index venues_point_gix on public.venues using gist (point);

-- ── groups ────────────────────────────────────────────────────────────────
create table public.groups (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  sport            text not null,
  description      text not null default '',
  outward_postcode text,
  point            geography(Point, 4326),
  privacy          text not null default 'invite_only'
                     check (privacy in ('public', 'invite_only', 'private')),
  skill_band       text not null default 'all',
  women_only       boolean not null default false,
  owner_id         uuid not null references public.profiles (id) on delete cascade,
  invite_code      text unique default encode(gen_random_bytes(6), 'hex'),
  is_seeded        boolean not null default false,
  created_at       timestamptz not null default now()
);
create index groups_point_gix on public.groups using gist (point);
create index groups_sport_idx on public.groups (sport);

-- ── group_members ─────────────────────────────────────────────────────────
create table public.group_members (
  group_id          uuid not null references public.groups (id) on delete cascade,
  profile_id        uuid not null references public.profiles (id) on delete cascade,
  role              text not null default 'member'
                      check (role in ('owner', 'organiser', 'member')),
  status            text not null default 'pending'
                      check (status in ('pending', 'active', 'removed', 'banned')),
  attendance_streak int not null default 0,
  joined_at         timestamptz not null default now(),
  primary key (group_id, profile_id)
);

-- ── sessions ──────────────────────────────────────────────────────────────
create table public.sessions (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.groups (id) on delete cascade,
  venue_id     uuid references public.venues (id) on delete set null,
  starts_at    timestamptz not null,
  ends_at      timestamptz,
  capacity     int,
  cost_pennies int,
  skill_band   text,
  recurrence   text,                            -- e.g. 'weekly:thu'
  status       text not null default 'scheduled'
                 check (status in ('scheduled', 'cancelled', 'completed')),
  notes        text not null default '',
  created_by   uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now()
);
create index sessions_group_idx on public.sessions (group_id, starts_at);

-- ── session_rsvps ─────────────────────────────────────────────────────────
create table public.session_rsvps (
  session_id         uuid not null references public.sessions (id) on delete cascade,
  profile_id         uuid not null references public.profiles (id) on delete cascade,
  status             text not null default 'going'
                       check (status in ('going', 'waitlist', 'declined', 'no_show', 'attended')),
  responded_at       timestamptz not null default now(),
  attended_marked_by uuid references public.profiles (id) on delete set null,
  primary key (session_id, profile_id)
);

-- ── messages ──────────────────────────────────────────────────────────────
create table public.messages (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  session_id uuid references public.sessions (id) on delete cascade,  -- null = group channel
  sender_id  uuid not null references public.profiles (id) on delete cascade,
  body       text not null,
  pinned     boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);
create index messages_group_idx on public.messages (group_id, created_at);

create table public.message_reactions (
  message_id uuid not null references public.messages (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  emoji      text not null,
  primary key (message_id, profile_id, emoji)
);

-- ── device_tokens (push) ──────────────────────────────────────────────────
create table public.device_tokens (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now(),
  primary key (profile_id, token)
);

-- ── reports (safety) ──────────────────────────────────────────────────────
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('user', 'message', 'group')),
  target_id   uuid not null,
  reason      text not null default '',
  status      text not null default 'open' check (status in ('open', 'reviewing', 'closed')),
  created_at  timestamptz not null default now()
);

-- ── Helper functions (SECURITY DEFINER to avoid RLS recursion) ─────────────
create or replace function public.is_group_member(gid uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from group_members
    where group_id = gid and profile_id = auth.uid() and status = 'active'
  );
$$;

create or replace function public.is_group_organiser(gid uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from group_members
    where group_id = gid and profile_id = auth.uid()
      and status = 'active' and role in ('owner', 'organiser')
  );
$$;

-- ── Enable RLS everywhere ──────────────────────────────────────────────────
alter table public.profiles          enable row level security;
alter table public.sport_ratings     enable row level security;
alter table public.venues            enable row level security;
alter table public.groups            enable row level security;
alter table public.group_members     enable row level security;
alter table public.sessions          enable row level security;
alter table public.session_rsvps     enable row level security;
alter table public.messages          enable row level security;
alter table public.message_reactions enable row level security;
alter table public.device_tokens     enable row level security;
alter table public.reports           enable row level security;

-- ── Policies ───────────────────────────────────────────────────────────────
-- profiles: self full access; others only if discoverable or co-member.
create policy profiles_self on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_read_discoverable on public.profiles
  for select using (visibility = 'discoverable');

-- sport_ratings: owner-managed; readable by anyone who can see the profile.
create policy ratings_self on public.sport_ratings
  for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- venues: anyone authed can read; creator can edit.
create policy venues_read on public.venues for select using (auth.uid() is not null);
create policy venues_write on public.venues
  for all using (created_by = auth.uid()) with check (created_by = auth.uid());

-- groups: readable if public or a member; owner creates; organiser edits.
create policy groups_read on public.groups
  for select using (privacy = 'public' or is_group_member(id) or owner_id = auth.uid());
create policy groups_insert on public.groups
  for insert with check (owner_id = auth.uid());
create policy groups_update on public.groups
  for update using (is_group_organiser(id)) with check (is_group_organiser(id));

-- group_members: members see their group's roster; self can request to join;
-- organisers manage; self can leave (delete own row).
create policy members_read on public.group_members
  for select using (is_group_member(group_id) or profile_id = auth.uid());
create policy members_join on public.group_members
  for insert with check (profile_id = auth.uid());
create policy members_self_leave on public.group_members
  for delete using (profile_id = auth.uid());
create policy members_organiser_manage on public.group_members
  for update using (is_group_organiser(group_id)) with check (is_group_organiser(group_id));

-- sessions: active members read; organisers write.
create policy sessions_read on public.sessions
  for select using (is_group_member(group_id));
create policy sessions_write on public.sessions
  for all using (is_group_organiser(group_id)) with check (is_group_organiser(group_id));

-- rsvps: members read their group's rsvps; self upserts own; organiser updates
-- (e.g. marks attendance).
create policy rsvps_read on public.session_rsvps
  for select using (
    exists (select 1 from sessions s where s.id = session_id and is_group_member(s.group_id))
  );
create policy rsvps_self_upsert on public.session_rsvps
  for insert with check (profile_id = auth.uid());
create policy rsvps_self_update on public.session_rsvps
  for update using (
    profile_id = auth.uid()
    or exists (select 1 from sessions s where s.id = session_id and is_group_organiser(s.group_id))
  );

-- messages: active members read non-deleted; members post as themselves;
-- author or organiser edits (pin/soft-delete).
create policy messages_read on public.messages
  for select using (is_group_member(group_id) and deleted_at is null);
create policy messages_insert on public.messages
  for insert with check (sender_id = auth.uid() and is_group_member(group_id));
create policy messages_update on public.messages
  for update using (sender_id = auth.uid() or is_group_organiser(group_id));

-- reactions: members of the message's group.
create policy reactions_rw on public.message_reactions
  for all using (
    exists (select 1 from messages m where m.id = message_id and is_group_member(m.group_id))
  ) with check (profile_id = auth.uid());

-- device_tokens: strictly self.
create policy tokens_self on public.device_tokens
  for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- reports: reporter can create + see their own.
create policy reports_self on public.reports
  for all using (reporter_id = auth.uid()) with check (reporter_id = auth.uid());

-- ── Auto-provision a profile row on signup ────────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
