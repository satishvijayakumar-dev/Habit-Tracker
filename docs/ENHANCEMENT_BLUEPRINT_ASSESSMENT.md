# Enhancement Blueprint — Assessment & Status

Assessment of the *ActivHealth Product Enhancement Blueprint* against the
current codebase. ✅ = shipped, 🟡 = partial, 🔭 = staged (needs backend / LLM /
third-party). Maps to the blueprint's own Phase 1–4 roadmap.

## Already shipped before this pass
| Area | Status |
|---|---|
| Persona onboarding (7 personas) + change persona | ✅ |
| Today: focus banner, AI next action, loop progress, quick actions, streak | ✅ |
| AI-recommended minutes per activity (override) | ✅ |
| Scientific calories: BMR/TDEE → intake + burn (Mifflin–St Jeor) | ✅ |
| Tappable insights (active min / sessions / star points) | ✅ |
| Live community: discover near you, create, join, group chat (RLS + PostGIS) | ✅ |
| Sign-in: Apple / Google / email | ✅ |
| Settings, reminders, security, Pro paywall | ✅ |
| Coarse geolocation (precise on device, ~1 km stored) | ✅ |

## Added in this pass (Phase 1 net-new)
| Blueprint item | What shipped |
|---|---|
| §4 "AI visible across the app" | ✅ **Coach chat input** — free-text → adaptive replies. **Now LLM-backed:** signed-in users hit the `coach-chat` Supabase edge function (Claude Haiku) for genuinely adaptive coaching (e.g. "I only have toast and beans, no protein today"); signed-out / offline / unconfigured falls back to the on-device `CoachBrain` rule engine. Quick-suggestion chips, "thinking" indicator, sign-in invite banner. |
| §4.3 Adaptive session modification | ✅ via the coach chat intents ("I only have 20 minutes", "my knees hurt", "make it easier"…). |
| §5 Nutrition natural-food engine | ✅ **Fuel** rebuilt: calorie + protein targets, goal selector (snack / full meal / post-workout), vegetarian toggle, natural-food suggestions (`NutritionEngine`). |
| §6 Points → meaningful rewards | ✅ **Badges/Achievements** (`Badges`): First Step, Consistent, 7-Day Mover, Strength Starter, Loop Closer, Century, Community Member — earned logic + progress hints, shown on You. |
| §6.5 Forgiving daily streak | ✅ **Daily active streak** — any health-positive action (loop or activity) keeps it alive; grace for an open today. Shown on Today + You. |
| §6.6 Streak protection | ✅ **Protect** action logs a light recovery to save the streak. |
| §8 Cosmetic: colour semantics, microcopy | 🟡 duotone stat tiles, gradient restraint, daily-streak/badge cards added. |

All new logic is pure + unit-tested (`coach_brain_test`, `nutrition_engine_test`,
`badges_test`, `daily_streak_test`) — 88 tests total, `flutter analyze` clean.

## Staged (Phase 2–3) — needs backend / LLM / partners
| Item | Why staged |
|---|---|
| Real leaderboards (individual / group / persona / consistency / comeback) | Needs a server-side, cheat-proof points ledger (design noted in `ACTIVHEALTH_REBUILD_BRIEF`). |
| Group challenges, events + RSVP, buddy matching | Schema exists (`sessions`, `session_rsvps`); needs UI + organiser tools. |
| ~~LLM coach (true free-form reasoning)~~ | ✅ **SHIPPED** — `coach-chat` edge function (Claude Haiku) on `activhealth-prod`, JWT-gated, with `CoachBrain` fallback. Founder sets `ANTHROPIC_API_KEY` secret to activate. |
| Real-world / partner rewards, coach marketplace, corporate wellness | Commercial partnerships + payments (Stripe Connect). |
| Meal logging → Fuel loop contribution, weekly nutrition insight | Needs a nutrition log table + UI. |
| Wearable integration, weather/location-aware suggestions | Phase 4. |
| Push notifications (smart nudges) | Needs device tokens + edge function fan-out (table already in schema). |

## Architecture alignment (blueprint §10)
The blueprint's module list maps cleanly onto what exists:
Persona Engine (onboarding + `selectedPath`), AI Coach Service (`CoachBrain`),
Activity Tracking (`HabitProvider` + SQLite), Nutrition (`NutritionEngine`),
Community (`CommunityService` + Supabase), Rewards (`Badges` + star points),
Location/Privacy (`GeoService`, coarse-only + RLS), Subscriptions (Pro paywall).
Leaderboard, Notification, and Payments services remain the main net-new
backend modules for Phase 2–3.

## Recommendation
Phase 1 of the blueprint is now substantially complete. The highest-leverage
next build is **server-side points + a single leaderboard** (turns the new
badges/points into social competition) followed by **sessions/RSVP UI** on the
community schema that already exists.
