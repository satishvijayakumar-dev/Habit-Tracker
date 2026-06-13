# ActivHealth — Shared-Infrastructure Backend

How ActivHealth's cloud community runs on the same accounts as DittoPix while
keeping the two products' data fully isolated.

## Decisions (2026-06-13)
1. **Separate Supabase project, shared org.** ActivHealth has its own database
   and auth (`activhealth-prod`, ref `lmzzfmpbnodbpozkdmbo`, `eu-west-1`), under
   the same Supabase org as `dittopix-prod`. Billing/ops/monitoring are shared;
   health + location data are **not** commingled with the consumer image product.
   Today: £0 (free tier, 2 projects). At launch: one Pro plan (~£20/mo) covers
   the org — that's the shared cost.
2. **Precise on device, coarse stored.** GPS is read on-device and rounded to
   ~1 km (`GeoService.coarsen`, 2 dp) before anything leaves the phone. The
   backend only ever holds/serves the coarse point (PostGIS `geography`).
3. **Supabase-first.** Flutter talks directly to Supabase (Auth + RLS + Realtime
   + PostGIS). The DittoPix Railway/Express service is reserved for shared
   cron/secrets later; ActivHealth needs no bespoke API server for v1.

## Connection (public, RLS-protected — safe in the app)
- URL: `https://lmzzfmpbnodbpozkdmbo.supabase.co`
- Publishable key: `sb_publishable_KdicLb4CYQMz-z8MMPIzBw_hOjsnVPp`
- Override at build: `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_KEY=…`
- The **service-role key is never in the client.**

## Schema (migrations in `supabase/migrations/`)
`profiles, sport_ratings, venues, groups, group_members, sessions,
session_rsvps, messages, message_reactions, device_tokens, reports` — the
full racquet/social-sports model (pickleball, badminton, tennis, padel, …).
PostGIS lives in the `extensions` schema. Geo discovery via `groups_near` RPC
(ST_DWithin). Writes via SECURITY INVOKER RPCs (`upsert_my_profile`,
`create_group`, `join_group`).

## Security posture
- **RLS on every table.** Profiles are private unless `discoverable` or
  co-member; groups visible only if public or you're a member; messages/sessions
  only to active members; organiser-gated writes via `is_group_organiser`.
- Supabase **security advisor: 0 errors**, 2 warnings — both the
  `is_group_*` RLS helpers, which are `SECURITY DEFINER` by necessity (avoid
  policy recursion) and only ever reveal the caller's own membership. `anon`
  execute is revoked; the signup trigger is not RPC-callable.
- A signup trigger auto-creates a `profiles` row for each new auth user.

## What's wired
- ✅ Backend: schema, RLS, PostGIS, discovery + write RPCs, advisor-clean.
- ✅ Flutter foundation: `supabase_flutter` + `geolocator` deps, guarded
  Supabase init (app stays local-first if offline), `SupabaseConfig`,
  `GeoService` (coarsen + permissioned fetch, unit-tested), `CommunityService`
  (auth, profile upsert, `groupsNear`, `myGroups`, create/join, realtime chat),
  `CommunityGroup`/`GroupMembership` models, iOS/Android location permissions.

## Next (not yet wired into UI)
- Email-OTP (or Apple/Google) **sign-in screen**; gate community behind auth.
- Swap the Community tab from local `LocalGroup` to live `CommunityService`
  (discover near me → join → group chat → sessions/RSVP).
- Attendance → feeds the existing local streak/activity system.
- Push (FCM/APNs via `device_tokens` + an Edge Function) for session reminders.
- Seed 2–3 real founder-run groups (pickleball/badminton) for cold start.
