# Equitrip for Android

Jetpack Compose + Material 3 client for the same Supabase backend as the iOS app, brought
to parity one screen at a time.

| Screen | State |
|---|---|
| Home | Parity, except the quick actions (New trip · Chat · Expense · Receipt), which arrive with those features |
| Itinerary | Trips list, past trips, trip page (hero, Timeline/Ledger, Everyone/Just you, day rail), booking sheet. No editing, map, recap, chat or invite yet |
| Equi | Conversation parity without cards or saved history. Trip, plan, money and people questions are answered on the phone (a port of `EquiQueryReader` rules + `EquiFacts`); only advice and small talk go to Groq, after the user agrees, with names and amounts redacted. See `equi/EquiPrivacy.kt` |
| Settle | Parity across all trips: summary, waiting on you, by-trip transfers, history. Settle opens a pay sheet (UPI link); recording and confirming a payment stay on iPhone until Android writes the audit trail |

- **Arithmetic:** the share and settlement maths is a port of iOS `Trip` + `SettlementEngine`.
  Mid-trip departures aren't modelled yet.
- **Look:** iOS `Brand` colours, the 15 avatar illustrations (same hash, so a person has one
  face on both platforms), and trip titles in their chosen style. Apple-only faces are replaced
  with OFL Google Fonts in `res/font`: Bebas Neue (Futura Condensed), Great Vibes (Snell
  Roundhand), Courier Prime (American Typewriter), and Nunito for SF Rounded figures.
- **Config:** the Supabase URL and key are read at build time from
  `../Equitrip/Services/SupabaseConfig.swift`. Override them with `supabase.url` /
  `supabase.key` in `local.properties`.

- **Equi → Groq:** through the `equi-chat` Edge Function (`../supabase/functions/equi-chat`), which
  holds the key: `supabase secrets set GROQ_API_KEY=…` then `supabase functions deploy equi-chat`.
  A debug build can instead read `groq.key` from `local.properties` to call Groq directly; release
  builds never carry a key.

```bash
./gradlew :app:installDebug
```

Needs JDK 17+ (Android Studio's bundled JBR works) and the SDK path in `local.properties`.
