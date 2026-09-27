// open-meteo — a relay to Open-Meteo for when the device's own IP is refused.
//
// Open-Meteo's free tier is keyless and limited per IP. A phone on a busy
// network (or a developer's Wi-Fi after a day of testing) gets "Daily API
// request limit exceeded" and the Weather Twin has no forecast. The app asks
// Open-Meteo directly first and only comes here on a 429, so this function's
// own egress is the fallback, not the main road. Answers are cached for ten
// minutes, so a group opening the same trip costs one upstream call.
//
//   { "url": "https://api.open-meteo.com/v1/forecast?latitude=…" }
//     → Open-Meteo's body and status, untouched
//
// Only *.open-meteo.com over https is relayed; it is not a general proxy.
// Signed-in users only. Nothing is logged or stored.
//
//          supabase functions deploy open-meteo

import { createClient } from "jsr:@supabase/supabase-js@2";

const CACHE_MS = 10 * 60_000;
const cache = new Map<string, { at: number; body: string }>();

function fail(status: number, message: string) {
  return new Response(JSON.stringify({ error: true, reason: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return fail(405, "POST only");

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return fail(401, "Not signed in");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return fail(401, "Not signed in");

  const body = await req.json().catch(() => null) as { url?: string } | null;
  let target: URL;
  try {
    target = new URL(body?.url ?? "");
  } catch {
    return fail(400, "Bad url");
  }
  if (target.protocol !== "https:" || !/(^|\.)open-meteo\.com$/.test(target.hostname)) {
    return fail(400, "Only open-meteo.com is relayed");
  }

  const key = target.toString();
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_MS) {
    return new Response(hit.body, { headers: { "Content-Type": "application/json" } });
  }

  try {
    const res = await fetch(key, { headers: { "User-Agent": "Equitrip relay" } });
    const text = await res.text();
    if (res.ok) cache.set(key, { at: Date.now(), body: text });
    return new Response(text, { status: res.status, headers: { "Content-Type": "application/json" } });
  } catch {
    return fail(502, "Couldn't reach Open-Meteo");
  }
});
