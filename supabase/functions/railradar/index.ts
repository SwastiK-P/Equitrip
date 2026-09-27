// railradar — the app's line to RailRadar (Indian Railways PNR + live running status).
//
// Why a function and not a key in the app: an IPA's strings can be read by anyone who has
// it, and every call spends the account's quota. Here the key is a function secret and
// only a signed-in user can spend it. Answers are cached briefly (a group of six opening
// the same train costs one call), and the upstream body is passed through untouched —
// turning it into a booking stays in Swift (`TrainLookupService`).
//
// Two actions:
//   { "action": "pnr",  "pnr": "1234567890" }                 → RailRadar `data` for /v1/pnr/{pnr}
//   { "action": "live", "train": "12952", "date": "YYYY-MM-DD" } → RailRadar `data` for /v1/trains/{n}/live
// Errors: { "error": { "message": "…" } } with RailRadar's own message when it gave one.
// PNRs are never logged.
//
//          supabase secrets set RAILRADAR_API_KEY=…
//          supabase functions deploy railradar

import { createClient } from "jsr:@supabase/supabase-js@2";

const BASE = "https://api.railradar.in/v1";
/** A PNR's chart/berths change a few times a day at most; live position changes by the minute. */
const TTL_MS = { pnr: 5 * 60_000, live: 60_000 };

function reply(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

const fail = (status: number, message: string) => reply(status, { error: { message } });

const cache = new Map<string, { at: number; data: unknown }>();

async function upstream(key: string, path: string, ttl: number) {
  const hit = cache.get(path);
  if (hit && Date.now() - hit.at < ttl) return reply(200, { data: hit.data, cached: true });

  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${key}`, Accept: "application/json" },
  });
  const body = await res.json().catch(() => null);
  if (!res.ok || !body?.success) {
    const message = body?.error?.message ?? body?.message ??
      (res.status === 404 ? "Not found" : "RailRadar couldn't answer that right now.");
    return fail(res.status === 404 ? 404 : 502, String(message));
  }
  cache.set(path, { at: Date.now(), data: body.data });
  return reply(200, { data: body.data, cached: false });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return fail(405, "POST only");

  // Signed-in users only: the JWT is checked against Supabase Auth, not just decoded.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return fail(401, "Not signed in");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return fail(401, "Not signed in");

  const key = Deno.env.get("RAILRADAR_API_KEY");
  if (!key) return fail(503, "Train lookup isn't configured");

  const body = await req.json().catch(() => null) as
    { action?: string; pnr?: string; train?: string; date?: string } | null;

  try {
    if (body?.action === "pnr") {
      const pnr = String(body.pnr ?? "").replace(/\D/g, "");
      if (pnr.length !== 10) return fail(400, "A PNR is 10 digits.");
      return await upstream(key, `/pnr/${pnr}`, TTL_MS.pnr);
    }
    if (body?.action === "live") {
      const train = String(body.train ?? "").replace(/\D/g, "");
      if (train.length < 4 || train.length > 5) return fail(400, "Bad train number");
      const date = /^\d{4}-\d{2}-\d{2}$/.test(body.date ?? "") ? `?date=${body.date}` : "";
      return await upstream(key, `/trains/${train}/live${date}`, TTL_MS.live);
    }
  } catch {
    return fail(502, "Couldn't reach RailRadar.");
  }
  return fail(400, "Bad request");
});
