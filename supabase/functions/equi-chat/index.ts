// equi-chat — the only way Equitrip's Android app reaches Groq.
//
// Why a function and not a key in the app: an APK's strings can be read by anyone who has
// it, and the Groq free tier's limits are shared by every install. Here the key is a
// function secret, only a signed-in Equitrip user can spend it, and Groq sees this
// function's address rather than the user's phone.
//
// It forwards text and streams the reply back. It never logs a request or reply body,
// stores nothing, and doesn't send Groq the user's id. The client can't choose the model,
// the token cap or the temperature — only the messages.
//
// Deploy:  supabase secrets set GROQ_API_KEY=gsk_...
//          supabase functions deploy equi-chat

import { createClient } from "jsr:@supabase/supabase-js@2";

/** Fast and small first; on the free tier's rate limit, the smaller Llama takes over. */
const MODELS = ["openai/gpt-oss-20b", "llama-3.1-8b-instant"];
const MAX_MESSAGES = 8;
const MAX_CHARS = 6000;

type Message = { role: "system" | "user" | "assistant"; content: string };

function fail(status: number, message: string) {
  return new Response(JSON.stringify({ error: { message } }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function valid(body: unknown): Message[] | null {
  const messages = (body as { messages?: unknown })?.messages;
  if (!Array.isArray(messages) || messages.length === 0 || messages.length > MAX_MESSAGES) return null;
  let total = 0;
  for (const m of messages) {
    if (!m || typeof m.content !== "string" || !["system", "user", "assistant"].includes(m.role)) return null;
    total += m.content.length;
  }
  if (total > MAX_CHARS) return null;
  return messages.map((m) => ({ role: m.role, content: m.content }));
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return fail(405, "POST only");

  // Signed-in users only: the JWT is checked against Supabase Auth, not just decoded.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return fail(401, "Not signed in");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return fail(401, "Not signed in");

  const key = Deno.env.get("GROQ_API_KEY");
  if (!key) return fail(503, "Equi's cloud helper has no Groq key");

  const messages = valid(await req.json().catch(() => null));
  if (!messages) return fail(400, "Bad request");

  let last: Response | null = null;
  for (const model of MODELS) {
    const upstream = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model,
        messages,
        stream: true,
        temperature: 0.5,
        max_completion_tokens: 400,
        ...(model.startsWith("openai/gpt-oss") ? { reasoning_effort: "low", include_reasoning: false } : {}),
      }),
    });
    if (upstream.ok && upstream.body) {
      return new Response(upstream.body, {
        headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-store" },
      });
    }
    last = upstream;
    if (upstream.status !== 429 && upstream.status < 500) break;
  }
  // Groq's error text, not the request that caused it.
  const detail = await last?.json().catch(() => null);
  return fail(last?.status ?? 502, detail?.error?.message ?? "Groq didn't answer");
});
