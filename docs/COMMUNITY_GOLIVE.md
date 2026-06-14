# Community Go-Live — Auth Configuration

The sign-in screen and the live community (discover near you, join, group
chat) are fully built in the app. What remains is **external provider
configuration** — OAuth can't be enabled from app code. Steps below, ~20 min.

Project: `activhealth-prod` (ref `lmzzfmpbnodbpozkdmbo`).
Redirect deep link (already registered in iOS Info.plist + AndroidManifest):

```
activhealth://login-callback/
```

## 1. Supabase redirect allow-list (required for all methods)
Supabase Dashboard → Authentication → URL Configuration → **Redirect URLs**,
add: `activhealth://login-callback/`

## 2. Email (works immediately — no provider needed)
Email OTP is on by default. To use the **6-digit code** flow the app expects:
Authentication → Email Templates → "Magic Link" → ensure the body includes
the token, e.g. add: `Your code is {{ .Token }}`.
(Free-tier email is rate-limited — fine for beta; add a custom SMTP before scale.)

## 3. Google
1. Google Cloud Console → APIs & Services → Credentials → **OAuth client ID**
   → Web application. Authorized redirect URI:
   `https://lmzzfmpbnodbpozkdmbo.supabase.co/auth/v1/callback`
2. Copy the **Client ID** and **Client secret**.
3. Supabase → Authentication → Providers → **Google** → enable, paste them.
   (No client IDs are baked into the app — it uses Supabase's hosted flow.)

## 4. Sign in with Apple (required by App Store when Google is offered)
1. Apple Developer → Identifiers → create a **Services ID**; enable "Sign in
   with Apple"; set the return URL to
   `https://lmzzfmpbnodbpozkdmbo.supabase.co/auth/v1/callback`.
2. Create a **Sign in with Apple key**; note the Key ID + Team ID.
3. Supabase → Authentication → Providers → **Apple** → enable; enter the
   Services ID, Team ID, Key ID, and key.
4. Xcode/Codemagic: add the **Sign in with Apple** capability to the Runner
   target. (The app's Apple button calls Supabase's OAuth flow.)

## 5. AI Coach (Claude Haiku) — set the Anthropic key
The smart, adaptive coach (e.g. "I can only eat toast and beans, no protein
today" → a sensible tailored reply) runs server-side in the **`coach-chat`
edge function** (already deployed). The Anthropic key lives **only** as a
Supabase secret — never in the app.

1. Get an Anthropic API key (console.anthropic.com). **Recommended:** mint a
   *separate* key from DittoPix's so ActivHealth's coach spend is attributable
   on its own line — same Anthropic account/billing is fine, just a distinct key.
2. Set it as a secret on `activhealth-prod`:
   - Dashboard → Edge Functions → **Secrets** → add `ANTHROPIC_API_KEY` = `sk-ant-…`
   - or CLI: `supabase secrets set ANTHROPIC_API_KEY=sk-ant-… --project-ref lmzzfmpbnodbpozkdmbo`
3. No redeploy needed — the function reads the secret at call time.

Behaviour & safety:
- The function is **JWT-gated** (`verify_jwt = true`): only signed-in
  ActivHealth users can call it, so coach usage is tied to a real account
  (no anonymous bill-running). Until a user signs in, the coach uses the
  on-device **rule-based** brain (`CoachBrain`) — still useful, just not adaptive.
- If `ANTHROPIC_API_KEY` is unset, or Anthropic errors/times out, the function
  returns `{ fallback: true }` and the app silently uses `CoachBrain`. So the
  coach **never shows an error** — it degrades gracefully.
- Model: `claude-haiku-4-5`, `max_tokens` 500, ~$1/$5 per 1M in/out tokens —
  a few hundredths of a penny per reply. The system prompt enforces "coaching,
  not medical advice" and tells users to stop for chest pain / dizziness.

## 6. (Optional) Anonymous "try without signup"
Authentication → Providers → enable **Anonymous sign-ins** if you want a
zero-friction "skip" path later. The app doesn't use it yet.

## How it works in the app
- `SignInScreen` offers Apple (iOS) / Google / Email. On success the auth
  deep-link returns to the app; the screen pops and the Community tab flips to
  live mode.
- On first sign-in, the app upserts the user's profile with their **coarse**
  location (≈1 km, rounded on-device) and `discoverable` visibility.
- Discovery uses the `groups_near` PostGIS RPC; join/create use the
  `join_group` / `create_group` RPCs; chat is realtime on the `messages` table.
- All reads/writes are RLS-protected (see `supabase/migrations/`).

## Verify after configuring
1. Build via Codemagic, install, open Community → opt in → Sign in.
2. Email: enter email → code → you should land in live mode.
3. Create a group → it appears under "Your groups"; open it → send a message.
4. On a second account, "Near you" should list the public group; Join → chat.
