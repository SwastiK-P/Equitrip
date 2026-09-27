// weather-union — the Weather Twin's line to Zomato's Weather Union station network.
//
// Why a function and not a key in the app: an IPA's strings can be read by anyone who has
// it, and the key carries a 1,000-calls-a-day budget shared by every Equitrip user. Here the
// key is a function secret, only a signed-in user can spend it, readings are cached per
// ~1 km cell for ten minutes (a group of six looking at the same hotel costs one call, not
// six), and a daily guard stops short of the limit so the last calls of the day don't 429.
//
// One action:
//   { "points": [{ "id": "…", "lat": 15.55, "lon": 73.75 }, …] }   up to 12 points
//     → { "readings": [{ id, status: "ok" | "no_station" | "error", reading?, cached, fetched_at }] }
//
// "no_station" is an answer, not a failure: Weather Union only covers the cities it has
// stations in, and the app falls back to Open-Meteo for everywhere else. The function never
// logs coordinates, stores nothing, and doesn't send Weather Union the user's id.
//
//          supabase secrets set WEATHER_UNION_API_KEY=…
//          supabase functions deploy weather-union

import { createClient } from "jsr:@supabase/supabase-js@2";

const BASE = "https://www.weatherunion.com/gw/weather/external/v0";
const MAX_POINTS = 12;
const CACHE_MS = 10 * 60_000;
/** Weather Union allows 1,000 a day; stop a little short so a burst can't tip it over. */
const DAILY_BUDGET = 950;

type Point = { id: string; lat: number; lon: number };
type Reading = {
  temperature: number | null;
  humidity: number | null;
  wind_speed: number | null;
  wind_direction: number | null;
  rain_intensity: number | null;
  rain_accumulation: number | null;
  aqi_pm_2_point_5: number | null;
  aqi_pm_10: number | null;
};
type Answer = { status: "ok" | "no_station" | "error"; reading?: Reading; fetched_at: string };

function reply(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

const fail = (status: number, message: string) => reply(status, { error: { message } });

const cache = new Map<string, { at: number; answer: Answer }>();
let spent = { day: "", count: 0 };

/** ~1.1 km cells: close enough that two bookings in one neighbourhood share a station. */
const cell = (p: Point) => `${p.lat.toFixed(2)},${p.lon.toFixed(2)}`;

function num(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

/** A station that answers with every field empty has told us nothing. */
function isEmpty(r: Reading) {
  return r.temperature === null && r.rain_intensity === null && r.humidity === null;
}

function spend(): boolean {
  const today = new Date().toISOString().slice(0, 10);
  if (spent.day !== today) spent = { day: today, count: 0 };
  if (spent.count >= DAILY_BUDGET) return false;
  spent.count += 1;
  return true;
}

async function fetchPoint(key: string, p: Point): Promise<Answer> {
  const fetched_at = new Date().toISOString();
  if (!spend()) return { status: "error", fetched_at };

  const url = `${BASE}/get_weather_data?latitude=${p.lat}&longitude=${p.lon}`;
  const res = await fetch(url, { headers: { "x-zomato-api-key": key } });
  if (res.status === 400) return { status: "no_station", fetched_at };
  if (!res.ok) return { status: "error", fetched_at };

  const body = await res.json().catch(() => null);
  const raw = body?.locality_weather_data;
  if (!raw || (typeof body?.status === "number" && body.status !== 200)) {
    return { status: "no_station", fetched_at };
  }

  const reading: Reading = {
    temperature: num(raw.temperature),
    humidity: num(raw.humidity),
    wind_speed: num(raw.wind_speed),
    wind_direction: num(raw.wind_direction),
    rain_intensity: num(raw.rain_intensity),
    rain_accumulation: num(raw.rain_accumulation),
    aqi_pm_2_point_5: num(raw.aqi_pm_2_point_5),
    aqi_pm_10: num(raw.aqi_pm_10),
  };
  return isEmpty(reading) ? { status: "no_station", fetched_at } : { status: "ok", reading, fetched_at };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return fail(405, "POST only");

  // Signed-in users only: the JWT is checked against Supabase Auth, not just decoded.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return fail(401, "Not signed in");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return fail(401, "Not signed in");

  // Both spellings: the dashboard accepts a hyphen that the CLI doesn't.
  const key = Deno.env.get("WEATHER_UNION_API_KEY") ?? Deno.env.get("WEATHER-UNION_API_KEY");
  if (!key) return fail(503, "Weather Union isn't configured");

  const body = await req.json().catch(() => null) as { points?: unknown } | null;
  const points = (Array.isArray(body?.points) ? body!.points : [])
    .filter((p): p is Point =>
      typeof p?.id === "string" && typeof p?.lat === "number" && typeof p?.lon === "number" &&
      Math.abs(p.lat) <= 90 && Math.abs(p.lon) <= 180
    )
    .slice(0, MAX_POINTS);
  if (points.length === 0) return fail(400, "Bad request");

  const readings = await Promise.all(points.map(async (p) => {
    const hit = cache.get(cell(p));
    if (hit && Date.now() - hit.at < CACHE_MS) return { id: p.id, ...hit.answer, cached: true };
    try {
      const answer = await fetchPoint(key, p);
      // Errors aren't cached: the next look should try again rather than repeat a blip.
      if (answer.status !== "error") cache.set(cell(p), { at: Date.now(), answer });
      return { id: p.id, ...answer, cached: false };
    } catch {
      return { id: p.id, status: "error", fetched_at: new Date().toISOString(), cached: false };
    }
  }));

  return reply(200, { readings });
});
