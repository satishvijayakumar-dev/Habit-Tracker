// ActivHealth account deletion.
//
// Runs in the activhealth-prod Supabase project. verify_jwt is on, so we can
// trust the caller's identity from their JWT. Using the service-role key
// (auto-injected as SUPABASE_SERVICE_ROLE_KEY), it deletes the calling user
// from auth.users — which CASCADES to public.profiles and every table that
// references it (groups, group_members, messages, reactions, device_tokens,
// etc.), so nothing personal is left behind.
//
// This satisfies Apple App Store Guideline 5.1.1(v): any app offering account
// creation must let the user delete their account from within the app.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...cors },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const token = authHeader.replace(/^Bearer\s+/i, '');
    if (!token) return json({ error: 'not_authenticated' }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Resolve the caller from their JWT — never trust a client-supplied id.
    const { data: userData, error: userErr } = await admin.auth.getUser(token);
    const userId = userData?.user?.id;
    if (userErr || !userId) return json({ error: 'not_authenticated' }, 401);

    // Cascades through public.profiles → all community data.
    const { error: delErr } = await admin.auth.admin.deleteUser(userId);
    if (delErr) return json({ error: 'delete_failed', detail: delErr.message }, 500);

    return json({ deleted: true });
  } catch (e) {
    return json({ error: 'error', detail: String(e) }, 500);
  }
});
