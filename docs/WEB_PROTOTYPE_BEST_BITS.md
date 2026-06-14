# Web Prototype — "Best Bits" Assessment & Roadmap

A Next.js web prototype of ActivHealth (separate from this Flutter app) was
reviewed as a feature-vision source. The Flutter app remains the shipping
product; we mine the prototype for *ideas* only (no code ports — React→Dart).

This is the curated list: what's genuinely useful, ruthlessly filtered.

## ✅ Folded in now (zero-backend wins)
| Idea | What we did |
|---|---|
| **MET-based per-exercise calories** | New pure `ActivityEnergy` (compendium MET table by activity type × intensity). Replaces the old intensity-only estimate so a run burns materially more than light strength at the same duration. Unit-tested. Workout logging now sets the activity type from each exercise's category so burn is attributed correctly. |
| **Deep running library + pace ranges** | Runner/Walker persona now gets a progressive, pace-guided weekly plan (easy / intervals / recovery / long). Session logger gained 6 running workouts (Easy, Intervals, Tempo, Long, Hill Repeats, Recovery) with pace + safety cues. |

## 🔜 Queued — next focused batches (small/no backend)
| Idea | Value | Effort | Notes |
|---|---|---|---|
| **Group chat reactions + pinned messages** | Engagement | Low–Med | Add `reactions`/`pinned` to the messages schema + UI on existing chat. |
| **Meal logging → completes the Fuel loop** | Closes nutrition loop, feeds weekly report | Med | Needs a nutrition log table + UI; offline keyword calorie estimate as default, Haiku coach refines. |
| **Progress photos** (before/after + weight + note) | Retention/motivation | Med | Local storage + privacy care (face product — keep on-device unless user opts to share). |

## 🔭 Staged — needs real backend (don't fake them)
- **Leaderboards (local + national star-points)** — needs a cheat-proof
  server-side points ledger (client-side is gameable). Already the #1 staged
  item; the prototype confirms the two-tier UX.
- **Referral / invite links** — growth lever; reuse the DittoPix pattern;
  needs server tracking.

## 💷 Later (Phase 3) — real revenue, real complexity
- **Coach marketplace** (PT listings: specialty/price/rating) — needs payments
  (Stripe Connect), vetting, trust & safety.
- **Monthly report + PDF export** — accountability layer once the *weekly*
  report is solid.

## ❌ Deliberately skipped (and why)
- **Nearby *individual*-user discovery + invite** — privacy risk for a
  location app; groups-first is safer (aligns with the safety backlog).
- **Simulated AI coach** — we now have real Claude Haiku, strictly better.
- **Onboarding tour, dark-mode toggle, mock avatars** — already covered
  (strong onboarding + coach pop-up; dark-first design).

## Bonus signal
Every prototype exercise carried a `visualNote` ("Animated demo: controlled
press…") — effectively a content spec for exercise demo animations. Useful
input for the open **visuals** gap (exercise GIFs/Lottie + coach mascot).
