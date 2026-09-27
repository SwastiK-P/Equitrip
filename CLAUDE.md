# Equitrip

SwiftUI group-travel planner + shared expense ledger: iOS 26.5 app, WidgetKit extension, watchOS app.
Booking PDFs and payment emails are read on-device with Apple Intelligence (FoundationModels).
Supabase (Postgres + RLS, Auth, Realtime, Storage) is the only backend.

## Orient cheaply

- **`docs/CODEMAP.md`** lists every Swift file with size, top-level types and purpose. Read it before
  grepping or listing folders. A Stop hook regenerates it (`scripts/codemap.py`) — never hand-edit.
- Files are named after their main type: `SplitMode` → `Model/SplitMode.swift`.
- Files marked ≥0.8k in the map: grep for the symbol, then read that range with offset/limit.
- Module rules in `.claude/rules/` (Intelligence, Gmail, Intents, shared/widget/watch targets) load automatically
  when you read files they cover.
- Don't read: `project.pbxproj` (folders are synchronized — adding/moving files needs no project
  edit), `build/`, `*.xcassets`, `docs/diagrams/` (slide generators, includes a stale copy of
  `GmailMark.swift`), `EQUITRIP_MASTER_DOC.md` (gitignored product narrative with outdated numbers).

## Build & run

- `scripts/build.sh` — builds app + widgets + watch; prints errors, warnings in changed files, one
  result line. **Never run raw `xcodebuild`** (~5k lines). Full log: `build/last-build.log`.
- `scripts/run.sh ["iPhone 17 Pro"]` — build, install and launch in the Simulator.
- No test target: a change is verified by a clean build, and behaviour by running the app.
- A clean build has 21 warnings (iOS 26 deprecations, MainActor isolation). Don't add to it. Warning
  counts only include recompiled files, so a cached build reports fewer.

## Layout — `Equitrip/`

| Folder | Holds |
|---|---|
| `Root/` | `RootTabView`: tab shell (Home · Itinerary · Settle · Equi); owns the stores and injects them |
| `Stores/` | `@Observable` state: `TripStore` (trips, writes, settlement realtime), `NotificationStore`, `AuditTrail` |
| `Model/` | Value types: `Trip`, `ItineraryItem`, `Traveller`/`CurrentUser`, `Money`, `SplitMode`, departures, audit events |
| `Services/` | `SupabaseRepository` (+ `SupabaseRows` DTOs), `AuthService`, photos, flights, widget/watch publishing, `*Config` |
| `Intelligence/` | PDF → itinerary pipeline |
| `Equi/` | On-device AI assistant tab. `Chat/` is the separate per-trip group chat between people |
| `Scanning/` | Camera: QR invite codes, boarding passes |
| `Gmail/` | Payment emails → detected expenses |
| `DesignSystem/` | `AppTheme`/`Palette` tokens, `Buttons`, `Surfaces`, `Layout` (`PaneMetrics`), pickers, toasts |
| `Home/ Itinerary/ NewTrip/ Expenses/ Settle/ Onboarding/ Auth/` | Feature screens |

Outside: `EquitripShared/` (compiled into every target), `EquitripWidgets/`,
`EquitripWatch Watch App/`, `supabase/migrations/` (gitignored, local only).

## Wiring

- `ContentView` routes launch → onboarding → auth → `RootTabView`.
- Views get stores via `@Environment(\.tripStore)`, `\.notificationStore`, `\.auditTrail`, `\.toastCenter`,
  `\.detectedExpenses`, `\.gmailSync` (`@Entry` at the bottom of each store's file). Services are `.shared`.
- Postgres is the only source of truth. No sample data, no offline fallback — failures surface
  (`TripStore.state`, `writeFailure`). Most queries are in `SupabaseRepository`; `TripStore`, `ChatService`,
  `TravellerDirectory`, `CoverStore`, `MediaStore` also use `AuthService.shared.client`.
- Assigning `TripStore.trips` republishes the widget/watch snapshot (`WidgetPublisher`) — don't call it yourself.
- Adaptive layout reads `@Environment(\.pane)`, never `UIDevice`.

## Invariants (enforced across files and in RLS — keep them)

- **No money from a model.** Amounts and times are copied from source text; names must appear in it.
- **Settlements** leave `.pending` only by the recipient (RLS `settlements_respond`); the payer can only create or withdraw.
- **Audit trail is append-only** (no update/delete policy). Corrections are new rows. It is not `NotificationStore`.
- **Departure previews** (`DeparturePlan`) ask the hypothetical `Trip` the normal share/balance questions — no parallel arithmetic.
- **Every table is RLS-gated**; the shipped publishable key has no privileges. Schema change = new numbered
  migration (`head -qn1 supabase/migrations/*.sql` indexes them).

## Conventions

- **Only Swift and `.xcassets` inside the four target folders** — plus `AppIcon.icon` (Icon Composer) in the app and
  watch folders, which `actool` compiles and which wins over the same-named `AppIcon.appiconset`. They're Xcode
  synchronized folders: any other file (`.md`, loose `.json`, scripts) is copied into the app bundle, and two with the
  same name fail the build ("Multiple commands produce …"). Notes go in `.claude/rules/` or `docs/`.
- Swift 5 mode. App + watch default to `MainActor` isolation; widgets don't.
- Light mode only. Colours from `AppTheme`/`Palette`; cards use `.cardSurface()`; screens sit on `CanvasBackground`.
- Top bars: `safeAreaBar(edge: .top)` + `.scrollEdgeEffectStyle(.soft, for: .top)`. Never on bottom bars.
- Doc comments explain *why* (the bug or decision behind the code). New types get one; its first
  sentence becomes the type's line in `docs/CODEMAP.md`.
- One main type per file. Split a screen past ~800 lines into `<Screen>Cards.swift` / `<Screen>Components.swift`.
- `Services/*Config.swift` and `Gmail/GmailConfig.swift` hold live keys — never copy them into chat, logs or other files.
