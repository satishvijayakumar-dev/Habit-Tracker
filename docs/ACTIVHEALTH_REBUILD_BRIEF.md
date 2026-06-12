# ActivHealth — Premium Rebuild Brief (v2.0)

**Prepared:** 13 June 2026 · **Baseline reviewed:** v1.5.0+15, commit `9e3794f` ("Add premium AI trainer journey"), main branch of `github.com/satishvijayakumar-dev/Habit-Tracker`
**Audience:** contract Flutter developer (+ backend). This document is self-contained.

---

## 1. Executive summary

ActivHealth v1.5.0 is a Flutter iOS app (~6,400 lines Dart, SQLite + Provider, built via Codemagic). The **habit-loop core is genuinely good** — build/quit habits, anchors/fallbacks/celebrations (Tiny Habits methodology), a correct streak engine, calendar heatmap, diary notes, local reminders. However:

- Every "premium" surface added in v1.4–1.5 (**AI coach, AI trainer plan, groups, share, nutrition**) is a **non-functional facade**: canned if/else strings, locally-seeded fake groups, clipboard-only "sharing". There is **no networking package in the app at all** — it cannot talk to any server.
- Visual layer is default-Material: **149 hard-coded color literals across 17 files, zero animation, zero haptics, zero charts, no custom font, broken dark mode**.
- The information architecture is cluttered: 5 tabs + 15 screens, the same stats shown in up to 4 places, and the one screen with 1-tap habit check-in (`today_screen.dart`) is **dead code — unreachable**, making the core action a 4-tap journey.

**Decision: structured rebuild of the app layer (~8–10 developer-weeks), keeping the data model, streak engine, and onboarding content.** Bolting a backend onto the current architecture would cost as much and inherit its bugs.

---

## 2. Critical bugs to fix regardless (P0)

| # | Bug | Location | Detail |
|---|---|---|---|
| 1 | **Permanent lockout without Face ID** | `lib/screens/security_gate.dart:48-62` | If biometrics are unavailable/unenrolled there is no continue path; `biometricOnly: true` blocks passcode fallback. Profiled users on such devices are locked out forever. |
| 2 | Security gate bypass | `security_gate.dart:149-156` | Pre-auth "Review profile" button opens ProfileScreen, exposing the data the gate protects. |
| 3 | Crash on empty habit list | `habit_detail_screen.dart:101-104`, `habit_provider.dart:474-475` | `orElse: () => habits.first` throws `StateError` when the list is empty. |
| 4 | Broken dark mode | `lib/main.dart:73-80` | `ThemeMode.system` + unbranded indigo dark seed + hard-coded light-only colors in screens → illegible UI for dark-mode users. |
| 5 | Misleading "AI" labels | `coach_screen.dart:97-134`, `workout_screen.dart:96` | Screens titled "AI Coach"/"AI trainer plan" run on if/else strings. App Store 4.0 (misleading metadata) risk. Remove the label or implement real AI. |
| 6 | Timezone-fragile day keys | `database_service.dart:232-251` | Completions keyed by local-midnight epoch millis; DST/travel corrupts streaks. Migrate to ISO `yyyy-MM-dd` strings. |

---

## 3. What to KEEP from the current codebase

1. **Data model concepts** (`lib/models/habit.dart`, `activity.dart`, `user_profile.dart`): build-vs-quit, checkoff-vs-amount, anchor/fallback/celebration/difficulty fields. Port schema to the new app (and later to Postgres).
2. **Streak engine logic** (`habit_provider.dart:473-561`) — port **with unit tests** (currently zero).
3. **Onboarding content** (`path_onboarding_screen.dart`): the 4-question path quiz, 7 personas (incl. Social Sports User), and per-persona starter habits. Keep content, move it to a data layer.
4. **Notification pattern** (`notification_service.dart`): lazy init, permission requested only when a reminder is set (this fixed two previous iOS crashes — do not regress it).
5. **Privacy posture**: approx-location off by default, city-string not GPS, honest "coming soon" copy.

**Throw away:** all screens as-built, the 534-line `HabitProvider` god-object (replace with Riverpod/Bloc + repository layer), SecurityGate as-is, all fake coach/groups/share/nutrition surfaces.

**Migration requirement:** existing TestFlight users' local SQLite (schema v5) must migrate losslessly into the new app.

---

## 4. New information architecture — 4 tabs, decluttered

Current: 5 tabs / 15 screens / star points shown in 4 places / habit check-in = 4 taps.
Target: **4 tabs, 1-tap check-in, one primary CTA per screen.**

| Tab | Contents | Absorbs |
|---|---|---|
| **Today** | Greeting ("Morning, {name}") + **Momentum Ring** hero + today's loops as 1-tap check-in tiles + today's session card + one coach nudge max | Dashboard, dead TodayScreen, AllHabits (segmented Today/All), latest activity |
| **Coach** | Conversational check-in (chips → typed-in coach reply), today's workout, week as 7-dot strip, nutrition as a "Fuel" topic | Nutrition screen (deleted as destination) |
| **Community** | Groups, sessions, RSVP, chat (Phase 1 backend below) | Share screen → native iOS share sheet (`share_plus`) |
| **You** | Charts (fl_chart), weekly recap card, streaks, body metrics, profile, settings | Stats + Profile; CSV export & legal copy move into Settings |

Center-docked **"+"** button → quick-log bottom sheet (activity type icon grid → duration stepper → done; 3 interactions).

**The user journey must add the missing emotional beats:**
- Onboarding beat 0: brand splash + value promise + **name capture** ("What should your coach call you?") — the app currently never asks the user's name.
- Persona reveal as a "magic moment" (animated ring forms around persona glyph).
- First-completion celebration: checkmark draw-on + medium haptic + the user's own stored celebration phrase (field exists in DB, currently never used).
- Streak milestones at 3/7/14/30 days (full-screen moment, shareable card).
- Monday push → "Your Week" story-style recap (replaces passive Report tab).
- Comeback grace after a missed day (streak-repair framing, not silent reset).
- Persona must shape the home screen: hero metric, loop ordering, coach vocabulary differ for Gym Builder vs Runner vs Social Sports vs Remote Worker.

---

## 5. Premium design system — "Midnight Coach" (dark-first)

Ship **dark-only** in v2.0 (like Whoop). One accent, calm surfaces, motion as reward.

### Color tokens
| Token | Hex | Use |
|---|---|---|
| bg | `#0B0D12` | Scaffold |
| surface1 / 2 / 3 | `#13161F` / `#1B2029` / `#242A36` | Cards / elevated / pressed |
| hairline | `#FFFFFF` @ 8% | Card borders (not shadows) |
| **accent "Pulse Coral"** | `#FF5A5F` | Primary actions, ring, brand |
| accentEmber | `#FF9966` | The ONLY sanctioned gradient: coral→ember |
| success mint | `#3DDC97` | Completions, streak-alive |
| info | `#6C8EFF` · warning `#FFB454` · danger `#FF4D4D` | |
| textPrimary / Secondary / Tertiary | `#F2F5F9` / `#98A2B3` / `#5C6678` | |

Habit accent set: coral `#FF5A5F`, mint `#3DDC97`, sky `#5BC0EB`, violet `#9B8AFB`, amber `#FFB454`, rose `#F472B6`, teal `#2DD4BF` (each with 16%-alpha container tint).

### Typography (google_fonts)
- **Sora** w600/700 for display & all numerals (tabular figures: `FontFeature.tabularFigures()`). Max weight w800 — kill all w900.
- **Inter** w400/500/600 for body/UI.
- Six sizes only: display 40 · headline 28 · title 20 · body 16 (1.5 lh) · label 13 · caption 12.

### Tokens
- Spacing: 4/8/12/16/24/32/48 (4pt grid, gutter 20).
- Radius: sm 10 · md 14 · lg 20 · xl 28 · full. Four values, in the theme, nowhere else.
- Depth via surface steps + hairline borders; one soft glow reserved for the ring (accent @ 25%, blur 24).

### Motion & haptics (currently zero of either)
- Fade-through page transitions 250ms (`animations` package); shared-axis between onboarding steps; hero tile→detail.
- All stats count up (TweenAnimationBuilder, 600ms easeOutCubic); ring sweeps 800ms on open.
- 120ms scale-to-0.97 card press; 40ms/item list stagger (cap 6).
- Haptics: selectionClick on chips; mediumImpact on habit complete; heavyImpact on ring close & milestones.
- Celebrations: checkmark draw-on + tile tint flash; ring-close radial glow pulse; confetti at streak 3/7/14/30. Respect `MediaQuery.disableAnimations`.
- Packages: `google_fonts`, `animations`, `fl_chart`, `confetti`, `share_plus`, (`flutter_animate` optional).

### Signature element — the **Momentum Ring**
One coral→ember gradient ring on Today: each protected loop fills an equal segment; inner thin mint arc = active minutes vs persona target. Center: count-up number + one-word state ("Building / Protected / Closed"). Replaces the dashboard hero, metric tiles, and "X of Y loops" text. Animates closed with glow + haptic.

### Per-screen notes
- **Onboarding:** dark brand moment, animated progress bar, card border-glow on select, persona-reveal ring animation, starter loops as 3 toggleable pre-checked cards, CTA "Start my first loop".
- **Today:** rebuilt HabitTile — 48px ring-checkbox fills with habit accent + check draw-on + haptic; **no strikethrough on completion** (tile compresses, tints success 8%, sorts down).
- **Coach:** kill the 3-hue gradient hero; coach = small pulsing coral orb on surface2; check-in chips → coach reply types in referencing name + persona + real data. Keep the rule engine but persist check-ins (currently thrown away on every launch); stage UI for a future LLM.
- **You:** weekly Momentum bar chart (fl_chart) + minutes sparkline + per-habit 14-day graded heat-strips (replaces solid-green month grid); "Your Week" shareable recap.
- **Workout:** uniform surface2 exercise cards, accent only on selection; sets×reps in Sora tabular; on log, ring on Today visibly advances (hero back to Today).
- Replace stock SnackBar/AlertDialog with branded toasts/bottom sheets throughout.

---

## 6. Community pillar — Social Sports (the differentiator)

**Positioning wedge:** not "find a court" — *"run your weekly session without WhatsApp admin hell, and have attendance feed your fitness streak."* No competitor connects social-sport attendance to a personal habit system.

**Sports taxonomy v1:** Pickleball, Badminton, Tennis, Padel, Squash, 5-a-side Football, Running, Walking, Gym buddy — each with icon, default session size/duration, skill scheme. (Pickleball is the wedge: fastest-growing UK racquet sport, organiser-heavy, rating-obsessed, underserved.)

**Core features (Phase 1):**
1. **Groups**: invite-only & private ONLY at launch (no empty public directory). Privacy ladder: public / invite_only / private. Women-only flag. Outward postcode (`WD17`) location only — never GPS.
2. **Sessions**: venue + time + capacity + optional cost + weekly recurrence. RSVP going/waitlist/declined; auto-promote from waitlist + push. "2 spots left" urgency.
3. **Skill matching**: per-sport bands (pickleball DUPR-style 2.0–8.0 self-declared; others Beginner→Advanced); soft enforcement v1.
4. **Group chat**: one channel per group + auto thread per session; reactions + organiser pin; report/block from day one (UK Online Safety Act — invite-only + 18+ + moderation keeps the burden proportionate).
5. **Attendance → streaks**: organiser marks attendance → writes an ActivityLog (sport, duration) → feeds weekly target, star points, habit streaks. Attendance streak per group + "reliable player" badge (% attended of RSVP'd).
6. **Organiser tools**: recurrence, approvals, attendance tap-list, announcements (pin + push), member attendance %.

**Backend: Supabase** (founder already operates Supabase in production — zero new ops). Auth (Apple/Google/email — Apple sign-in mandatory on iOS), Postgres + RLS, Realtime for chat/RSVP, Edge Functions for push fan-out (FCM/APNs) and waitlist promotion, Storage for avatars. Flutter: `supabase_flutter`, `firebase_messaging`. **SQLite stays as the local-first cache**; `ActivityLog` gains optional `session_id`.

**Draft schema (tables + key columns):**
```
profiles(id→auth.users, display_name, avatar_url, outward_postcode, lat/lng centroid,
         visibility default 'hidden')
sport_ratings(profile_id, sport, rating_band, numeric_rating?, verified)
venues(id, name, outward_postcode, indoor, court_count, booking_url, price_note)
groups(id, name, sport, description, outward_postcode, privacy default 'invite_only',
       skill_band, women_only, owner_id, invite_code, is_seeded)
group_members(group_id, profile_id, role owner|organiser|member,
              status pending|active|removed|banned, attendance_streak)
sessions(id, group_id, venue_id?, starts_at, ends_at, capacity, cost_pennies?,
         skill_band?, recurrence 'weekly:thu', status)
session_rsvps(session_id, profile_id, status going|waitlist|declined|no_show|attended,
              attended_marked_by?)
messages(id, group_id, session_id?, sender_id, body, pinned, deleted_at?)
message_reactions(message_id, profile_id, emoji)
device_tokens(profile_id, token, platform)
reports(id, reporter_id, target_type user|message|group, target_id, reason, status)
-- later: matches, referrals, star_points_ledger (server-side, cheat-proof leaderboard)
```
RLS: groups readable if public OR member; sessions/messages readable to active members; attendance writable by organiser role only.

**Deferred (Phase 2+):** public discovery directory (only after ~20–30 active groups), nearby players (opt-in visibility), real local leaderboards (only where ≥~30 people in an area), referrals (reward anchored to first *attendance*, not signup), match results → real ratings. **Deferred indefinitely:** PT/coach marketplace directory (cold-start squared); monetise the *session* instead via Stripe Connect organiser payments (Phase 3, first paid tier = organiser tools £5–8/mo).

**Cold start (founder actions, not dev work):** be the first organiser (one weekly badminton/pickleball session, attendees RSVP via app); convert WhatsApp organisers one at a time (one organiser = 10–25 players); saturate one postcode corridor (Watford/Harrow) before any other geography; seeded groups must be real sessions the founder attends, flagged `is_seeded`.

---

## 7. Phased delivery plan (one strong Flutter dev + backend, ~8–10 weeks)

| Phase | Weeks | Scope | Exit criteria |
|---|---|---|---|
| **0. Foundation** | 1–2 | New project skeleton: design tokens + dark theme + Sora/Inter, go_router, Riverpod (or Bloc) + repository layer, Sentry/Crashlytics + analytics, CI with tests. 4-tab IA shell. | Token-only styling (zero raw colors in screens); CI green |
| **1. Habit core port** | 3–4 | Port models/streak engine **with unit tests**, lossless SQLite v5 migration, Today tab with Momentum Ring + 1-tap tiles + celebrations + haptics, quick-log sheet, You tab with fl_chart. Fix all §2 bugs. | Existing user DB migrates; check-in = 1 tap; streak tests pass; dark-mode clean |
| **2. Backend + community v1** | 5–7 | Supabase auth + profiles + schema above, invite-only groups, sessions/RSVP/waitlist, group chat (Realtime), push notifications, attendance→ActivityLog→streaks, report/block. | Two real devices can join a group, RSVP, chat, get pushed, and attendance feeds the ring |
| **3. Coach + polish** | 8–9 | Persisted daily check-ins, coach reply engine referencing name/persona/history (rule-based now, LLM-ready interface via edge-function proxy — never ship API keys in app), weekly recap + milestone moments, onboarding rebuild with name capture + persona reveal. | "AI" label only where a model actually responds, or relabelled "Coach" |
| **4. Hardening & ship** | 10 | TestFlight beta, accessibility pass (44pt targets, labels, reduce-motion), App Store assets, Codemagic release pipeline with the post-processing step fixed. | App Store submission |

**Non-negotiables for acceptance:**
1. No raw `Colors.*`/hex in screen files — tokens only.
2. Unit tests on streak engine + DB migrations; widget tests on check-in flow.
3. Lossless migration for existing installs.
4. Face ID optional with passcode fallback and an escape path — never a hard gate.
5. Everything labelled "AI" must be backed by a model, or renamed.
6. Crash reporting + analytics live from first beta build.
7. One primary CTA per screen; habit check-in is 1 tap from app open.

---

## 8. Current-state reference (for the developer's orientation)

- Repo: `github.com/satishvijayakumar-dev/Habit-Tracker`, main @ `9e3794f` (v1.5.0+15). iOS built on Codemagic (Mac mini M2, Xcode 26.4); note the "post-processing failed" publish step needs fixing in `codemagic.yaml`.
- Real today: habit CRUD/streaks/heatmap/diary, activity log, profile+BMI+body metrics, local reminders, Face ID gate (buggy), CSV-to-clipboard.
- Fake today (do not assume these work): AI coach (if/else strings, check-ins not persisted, mood unused), AI trainer plan (3 hardcoded text variants), plan progress ticks (any session ticks next step), groups (3 locally-seeded fake groups, join = local boolean), nearby (locked placeholder), share (clipboard only), nutrition (one protein formula + 3 static cards), star points (local formula, compared with nobody), "motion-guided" copy (no such feature).
- Vision prototype (Next.js, `workspace zip /home/user/activhealth`): treat as a feature wishlist only — its own social features are also mocks/toast-only; its useful unported content = 25-exercise library with MET calorie maths, workout star-ratings, streak-protection prompt, nutrition keyword logging, progress photos, monthly report concept.
