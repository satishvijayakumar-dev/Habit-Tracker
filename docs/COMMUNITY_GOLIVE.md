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

App identity (for reference): bundle ID `com.satisapps.habitTracker`,
URL scheme `activhealth`, deep link `activhealth://login-callback/`.

> Sequencing: **Google works on the current build** the moment it's enabled
> (hosted flow, nothing app-side). **Apple needs a new build** because it
> requires the "Sign in with Apple" entitlement on the Runner target.

## 3. Google  (≈10 min · no app rebuild)
1. Google Cloud Console → **OAuth consent screen** → External; set app name
   "ActivHealth", support email, save (Testing mode is fine to start).
2. APIs & Services → Credentials → **Create OAuth client ID** → **Web
   application**. Authorized redirect URI (exact):
   `https://lmzzfmpbnodbpozkdmbo.supabase.co/auth/v1/callback`
3. Copy the **Client ID** and **Client secret**.
4. Supabase → Authentication → Providers → **Google** → enable, paste both, save.
   (No client IDs are baked into the app — it uses Supabase's hosted flow, so
   build 17 picks this up with no rebuild.)

## 4. Sign in with Apple (≈20 min · NEEDS a new build)
Requires an Apple Developer Program membership.
1. Apple Developer → Certificates, IDs & Profiles → **Identifiers**:
   - Ensure the **App ID** `com.satisapps.habitTracker` has the **Sign in with
     Apple** capability ticked.
   - Create a **Services ID** (e.g. `com.satisapps.habitTracker.signin` — it
     MUST differ from the bundle ID). Enable **Sign in with Apple** →
     Configure: Primary App ID = `com.satisapps.habitTracker`;
     Domain = `lmzzfmpbnodbpozkdmbo.supabase.co`;
     Return URL = `https://lmzzfmpbnodbpozkdmbo.supabase.co/auth/v1/callback`.
2. **Keys** → create a key with **Sign in with Apple** enabled; download the
   `.p8` (one-time). Note the **Key ID** and your **Team ID**.
3. Supabase → Authentication → Providers → **Apple** → enable; enter:
   Client ID = the **Services ID** (`…signin`), Team ID, Key ID, and paste the
   `.p8` contents.
4. **Add the entitlement + rebuild:** the Runner target needs the
   `com.apple.developer.applesignin` entitlement (and the provisioning profile
   must include the capability). Then Codemagic build 18+ → Apple goes live.

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
