// ActivHealth AI Coach proxy.
//
// Runs in the activhealth-prod Supabase project. Holds the Anthropic key as a
// secret (never in the app) and calls Claude Haiku to give clever, adaptive
// coaching replies. verify_jwt is on, so only signed-in ActivHealth users can
// call it — that also lets us attribute/limit usage per user.
//
// If ANTHROPIC_API_KEY isn't set yet, it returns { fallback: true } so the app
// silently uses its on-device rule-based coach instead of erroring.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY');
const MODEL = 'claude-haiku-4-5';

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

function buildSystem(ctx: Record<string, unknown>): string {
  const name = (ctx.name as string) || 'the user';
  const persona = (ctx.persona as string) || 'general fitness';
  const goal = (ctx.goal as string) || 'build consistency';
  const energy = (ctx.energy as string) || 'steady';
  return [
    `You are ActivHealth's AI fitness coach talking to ${name}.`,
    `Their persona is "${persona}", their goal is "${goal}", and today's energy is "${energy}".`,
    'Be warm, practical, specific and concise — 2 to 4 sentences, like a supportive human coach.',
    'Adapt to exactly what they say: their available time, energy, injuries, equipment, and the food they actually have.',
    'If food is limited, work with it cleverly — e.g. beans on wholemeal toast is already a solid protein-and-fibre meal; suggest one simple add (an egg, yoghurt) only if they might have it.',
    'This is coaching support, NOT medical advice. Tell them to stop and seek medical help for sharp pain, chest pain, dizziness, or unusual breathlessness. Never diagnose.',
    'Plain text only — no markdown headings, no bullet lists unless truly needed.',
  ].join(' ');
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { message, context } = await req.json();
    if (typeof message !== 'string' || message.trim().length === 0) {
      return json({ error: 'message required' }, 400);
    }
    if (!ANTHROPIC_API_KEY) {
      return json({ fallback: true, reason: 'not_configured' });
    }

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 500,
        system: buildSystem((context as Record<string, unknown>) ?? {}),
        messages: [{ role: 'user', content: String(message).slice(0, 2000) }],
      }),
    });

    if (!res.ok) {
      return json({ fallback: true, reason: `anthropic_${res.status}` });
    }

    const data = await res.json();
    const reply = (data.content ?? [])
      .filter((b: { type: string }) => b.type === 'text')
      .map((b: { text: string }) => b.text)
      .join('')
      .trim();

    if (!reply) return json({ fallback: true, reason: 'empty' });
    return json({ reply, source: 'ai' });
  } catch (_e) {
    return json({ fallback: true, reason: 'error' });
  }
});
