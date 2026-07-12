# ActivHealth — App Store Connect listing pack

Copy-paste ready. Character limits noted. Fill `[PLACEHOLDERS]` before submitting.

---

## Name & subtitle
- **App name (30 chars max):** `ActivHealth`
- **Subtitle (30 chars max):** `Your adaptive AI fitness coach` (30)

## Promotional text (170 chars max — editable without a new build)
```
Meet the fitness coach that adapts to your real life — your time, energy, and even what's in your fridge. Build habits that actually stick.
```

## Keywords (100 chars max, comma-separated, NO spaces between)
```
fitness,ai coach,habit,tracker,running,pace,calories,workout,health,wellness,community,steps,strength,gym
```
(97 chars. Don't repeat words already in the name/subtitle — Apple indexes those separately.)

## Description
```
ActivHealth is the fitness companion that actually adapts to you.

Most apps hand you a generic plan and expect you to fit your life around it. ActivHealth does the opposite. Tell it what's going on — "I only have 20 minutes," "no protein in the house today," "my knee's sore" — and your AI coach adjusts on the spot with practical, human advice.

WHY PEOPLE LOVE IT

• Adaptive AI coach — real, conversational guidance that works with the time, energy, equipment, and food you actually have. Not canned tips.

• Habits that stick — tiny, forgiving daily loops with a streak that protects you on the days life gets in the way.

• Science-based calories — MET-based burn per activity and Mifflin–St Jeor energy targets, not vague guesses.

• A running library that coaches your pace — easy runs, intervals, tempo, long runs, hill repeats and recovery, each with target paces and safety notes.

• Choose your path — pick from focused personas (from "just getting moving" to "training hard") and switch anytime.

• A community that gets you — discover like-minded people nearby for walking, badminton, tennis, the gym and more. Create a group, join one, chat. Your exact location is never shared — only a rough area, and only if you opt in.

• Private by design — your data is local-first and yours. Delete your account and everything with one tap, any time.

ActivHealth gives you general fitness and wellbeing guidance and is not a substitute for professional medical advice. Always check with a qualified professional before starting a new programme, and stop if you feel unwell.

Start today. Your coach is ready.
```

## What's New (for this version)
```
• Fresh new look — meet our heart-and-pulse icon.
• Sign in with Apple, Google, or email.
• See who you're signed in as, and delete your account any time from Settings.
• Reliability improvements under the hood.
```

## URLs (required)
- **Privacy Policy URL:** `[HOSTED URL — see hosting note below]` (required)
- **Support URL:** `[e.g. https://yourdomain.com/support or a simple contact page]` (required)
- **Marketing URL:** `[optional]`

---

## App Privacy — "nutrition label" answers (App Store Connect → App Privacy)

**Do you or your partners collect data from this app?** → **Yes**
**Do you use data to track users?** → **No** (no cross-app/website tracking, no ads)

Declare these **data types**, all **linked to the user's identity**, all used for **App Functionality** only (none for tracking or advertising):

| Category | Data type | Notes |
|---|---|---|
| Contact Info | Email address, Name | From sign-in (email / Apple / Google) |
| Health & Fitness | Fitness | Activities, workouts, weight, goals, habits |
| Location | Coarse Location | Only if community enabled; ~1 km, never precise |
| User Content | Other User Content | Community chat messages |
| Identifiers | User ID | Account identifier |
| Diagnostics | Crash Data, Performance Data | Via Sentry, only if a DSN is configured |

If you have **not** enabled Sentry (no DSN set) for the submitted build, omit the Diagnostics row. If community is enabled, keep Location + User Content.

---

## Age rating
Suggested: **12+**. Because ActivHealth includes **user-generated content** (community chat), when you complete the Age Rating questionnaire, answer honestly for "unrestricted web access" (No) and user-generated content. See the review note below — UGC brings extra requirements.

---

## ⚠️ Review-readiness notes (read before submitting)

**1. Reviewer demo account (REQUIRED).** Sign-in gates the coach and community, so Apple's reviewer needs a working login. In App Review Information, provide a test account:
- Email: `[a test email you control]` + note "use email magic-link" **or** provide Apple/Google test creds.
- Because sign-in uses a magic link / OAuth, add a clear note: *"Tap Sign in → continue with email; a magic link is sent. Alternatively review with the provided Apple account."* Consider adding a simple demo login if magic-link is awkward for the reviewer.

**2. User-generated content (Apple Guideline 1.2) — NOW ADDRESSED.** Because the community has chat, Apple requires ALL of:
- ✅ A EULA / terms — Terms of Service.
- ✅ A way to **report** objectionable content — long-press a message → Report (writes to `reports`).
- ✅ A way to **block** abusive users — long-press a message → Block (per-user `blocked_users`, filters their messages).
- ✅ Discoverable safety info — shield icon in each group chat explains guidelines + report/block.
- ⚠️ **Acting on reports within 24 hours** — operational: monitor the `reports` table and act. Set up a way to see new reports (e.g. a Supabase dashboard query or a simple email alert).
- ✅ Published contact info (support email).

For the reviewer, mention in App Review notes: *"Community moderation: long-press any message to report it or block the sender; a safety guide is behind the shield icon in group chats."*

**3. Sign in with Apple.** Because you offer Google sign-in, Apple **requires** Sign in with Apple to be offered too (Guideline 4.8) — now configured; verify it works on the submitted build.

**4. Account deletion.** ✅ Implemented (Settings → Delete account). Apple checks for this on any app with account creation.

**5. Location purpose string.** Ensure `Info.plist` `NSLocationWhenInUseUsageDescription` clearly explains community discovery (e.g. "ActivHealth uses your location to find fitness groups near you. Only your approximate area is ever shared, and only if you opt in.").

---

## Hosting the Privacy Policy & Terms (you need a public URL)
Quickest options:
- **GitHub Pages** from this repo — enable Pages, drop the `.md` files (or rendered HTML) in a `/docs` site; you get `https://satishvijayakumar-dev.github.io/...`.
- A page on your own domain.
- Any free static host (Netlify, Vercel, Cloudflare Pages).

Ask and I'll convert `PRIVACY_POLICY.md` / `TERMS_OF_SERVICE.md` into ready-to-host standalone HTML.
