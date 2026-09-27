// nugen-reader — how Equitrip's booking import reaches a Nugen domain-aligned model.
//
// Why a function and not a key in the app: an IPA's strings can be read by anyone who has
// it, and Nugen bills per call. Here the key is a function secret (NUGEN_API_KEY), only a
// signed-in Equitrip user can spend it, and Nugen sees this function's address rather
// than the user's phone.
//
// It does two things and nothing else:
//   { "action": "models" }                          the deployed aligned models, for the picker
//   { "action": "read_day", "model": id, "day": s }  one itinerary day → {items, confidence}
//
// The client can't choose the instructions, the token cap or the temperature — only which
// of this account's deployed aligned models reads, and the day's text. DAY_SYSTEM is the
// prompt the model was aligned on (scripts/nugen/make_dataset.py); change both together.
// It never logs a request or reply body, stores nothing, and doesn't send Nugen the user's id.
//
//          supabase secrets set NUGEN_API_KEY=…
//          supabase functions deploy nugen-reader
//
// The client can choose BOOKING_MODEL or any of this account's deployed aligned models.

import { createClient } from "jsr:@supabase/supabase-js@2";

const NUGEN = "https://api.nugen.in/api/v3";
const MAX_DAY_CHARS = 4000;

// The app's default booking reader (BookingReader.nugenDefault). Allowed even when
// /models/aligned doesn't list it, so the default can't 404 into the pattern parser.
const BOOKING_MODEL = "model_01m3gncr4m0jbnqf";

const DAY_SYSTEM = `You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.`;

type Model = { id: string; name: string; base: string };

function reply(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

const fail = (status: number, message: string) => reply(status, { error: { message } });

/** Deployed aligned models, cached briefly: the picker and every day of an import ask. */
let cached: { at: number; models: Model[] } | null = null;

async function deployedModels(key: string): Promise<Model[]> {
  if (cached && Date.now() - cached.at < 5 * 60_000) return cached.models;
  const res = await fetch(`${NUGEN}/models/aligned?limit=100`, {
    headers: { Authorization: `Bearer ${key}` },
  });
  if (!res.ok) throw new Error(`Nugen models ${res.status}`);
  const body = await res.json();
  // Nugen lists them under `domain_aligned_models` (see scripts/nugen_align.py).
  const rows: Record<string, unknown>[] = Array.isArray(body)
    ? body
    : body.domain_aligned_models ?? body.models ?? body.data ?? body.items ?? [];
  const models = rows
    // A row without a status is kept: the listing doesn't always carry one, and
    // an undeployed model only costs a failed read that falls back to patterns.
    .filter((m) => m.deployment_status == null || String(m.deployment_status).toUpperCase() === "DEPLOYED")
    .map((m) => ({
      id: String(m.model_id),
      name: String(m.model_name ?? m.model_id),
      base: String(m.base_model_name ?? m.base_model_id ?? ""),
    }));
  cached = { at: Date.now(), models };
  return models;
}

/** One chat completion. The "Reasoning" base models think out loud unless told not to;
 *  a base that doesn't take the `reasoning` field gets asked again without it. */
async function complete(key: string, model: string, day: string) {
  const request = (withReasoning: boolean) =>
    fetch(`${NUGEN}/inference/chat/completions`, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: DAY_SYSTEM },
          { role: "user", content: day },
        ],
        temperature: 0,
        max_tokens: 900,
        stream: false,
        ...(withReasoning ? { reasoning: { enabled: false, exclude: true } } : {}),
      }),
    });

  let res = await request(true);
  if (res.status === 400 || res.status === 422) res = await request(false);
  return res;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return fail(405, "POST only");

  // Signed-in users only: the JWT is checked against Supabase Auth, not just decoded.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return fail(401, "Not signed in");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return fail(401, "Not signed in");

  const key = Deno.env.get("NUGEN_API_KEY");
  if (!key) return fail(503, "The booking reader has no Nugen key");

  const body = await req.json().catch(() => null) as
    | { action?: string; model?: unknown; day?: unknown }
    | null;

  try {
    if (body?.action === "models") {
      // The app's default reader is always offered, first, even if the listing fails or omits it.
      const listed = await deployedModels(key).catch(() => [] as Model[]);
      const booking = listed.find((m) => m.id === BOOKING_MODEL) ??
        { id: BOOKING_MODEL, name: "Nugen Domain-Aligned", base: "" };
      return reply(200, { models: [booking, ...listed.filter((m) => m.id !== BOOKING_MODEL)] });
    }

    if (body?.action === "read_day") {
      const model = typeof body.model === "string" ? body.model : "";
      const day = typeof body.day === "string" ? body.day : "";
      if (!day.trim() || day.length > MAX_DAY_CHARS) return fail(400, "Bad request");
      // Only this account's own deployed models — the key isn't a general-purpose one.
      if (model !== BOOKING_MODEL && !(await deployedModels(key)).some((m) => m.id === model)) {
        return fail(404, "That model isn't deployed");
      }

      const res = await complete(key, model, day);
      if (!res.ok) {
        const detail = await res.json().catch(() => null);
        return fail(res.status, detail?.detail ?? detail?.error?.message ?? "Nugen didn't answer");
      }
      const answer = await res.json();
      return reply(200, {
        content: String(answer?.choices?.[0]?.message?.content ?? ""),
        confidence: typeof answer?.confidence_score === "number" ? answer.confidence_score : null,
      });
    }

    return fail(400, "Bad request");
  } catch (e) {
    return fail(502, e instanceof Error ? e.message : "Nugen didn't answer");
  }
});
