<div align="center">

<img src="docs/screenshots/icon.png" width="120" alt="">

# Equitrip

Group travel, planned and paid for together.

![Swift](https://img.shields.io/badge/Swift-5-F05138?style=flat-square&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0B84FF?style=flat-square&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-1A1A1A?style=flat-square&logo=apple&logoColor=white)
![watchOS](https://img.shields.io/badge/watchOS-1A1A1A?style=flat-square&logo=apple&logoColor=white)

<br>

<img src="docs/screenshots/hero.png" width="920" alt="">

</div>

<br>

Equitrip holds one shared record of a trip: the plan everyone is following and the
money everyone has spent on it. Bookings arrive as a PDF and become a timeline.
Receipts and payment emails are read on the device that took the photograph or
holds the mailbox. When the trip ends, the balances collapse into the fewest
transfers that clear them, and the group settles.

It is a SwiftUI app for iPhone and iPad, with widgets, a watchOS companion, and
Supabase as its only backend.

<br>

## The plan

A trip can be typed in, or imported. Hand it a booking PDF and the flights,
hotels, transfers and activities in it are laid onto a day-by-day timeline, each
one priced and attributed to the people it covers.

The plan is then read back. A consistency pass compares the times two bookings
state and says what they imply about each other — a hotel check-in before the
flight lands, two cities in the same hour. A flight number resolves to a route,
scheduled times and live status. A boarding pass scans from the camera.

People join by QR code or invite code, and the trip is shared from that moment.

## The money

Every booking carries three things a shared spreadsheet leaves out: who was on it,
who paid for it, and how it divides. Splits are equal, by share, by exact amount,
or exclude the people who weren't there. Currency belongs to the trip, so a group
can run one trip in rupees and the next in dollars.

Two things save the typing. A photograph of a receipt is read line by line, its
taxes and tips reconciled against its total, and opened in the booking editor for
confirmation. A connected mailbox is scanned for the messages that look like
payments, which are queued as detected expenses to be filed against a trip.

Both happen on the device. Nothing is sent anywhere to be understood.

## Settling up

Balances are reduced to the fewest transfers that clear every one of them, and
recalculated whenever anything changes.

A settlement is a claim rather than a fact. The payer records what they paid and
how, with proof; only the recipient can accept it. UPI links open whichever app
is already on the phone. Someone leaving part-way through gets a statement worked
out before anyone commits to it, which the rest of the group answers.

Every change is kept. The audit trail is append-only — a correction is a new
entry, never an edit to an old one.

## Along the way

Each trip has a thread. Polls, meetups, bring-lists, places, photos and the
bookings themselves are attachments in it rather than links out of it.

Equi answers questions about the trip in front of you — what's next, who still
owes you, where the money is going — using Apple Intelligence on device. The same
answers are available through Siri, Spotlight, Shortcuts, Control Centre and the
Action button, and on the Home Screen, the Lock Screen and the wrist.

<br>

## Architecture

```
Equitrip ────────┐
EquitripWidgets  ├── EquitripShared ──> Supabase · Postgres, RLS, Auth, Realtime, Storage
EquitripWatch ───┘
```

**Postgres is the source of truth.** There is no sample data and no offline
fallback: a failed read or write is surfaced in the interface rather than hidden
behind stale state. Every table is RLS-gated, and the publishable key shipped in
the app carries no privileges of its own.

**State lives in observable stores.** `TripStore`, `NotificationStore` and
`AuditTrail` are owned by `RootTabView` and reach views through the environment.
Assigning `TripStore.trips` republishes the snapshot the widgets and the watch
read; nothing else may publish it.

**Intelligence is local.** `Intelligence/`, `Receipts/` and `Gmail/` run Apple's
FoundationModels and Vision on the device. A rule-based parser sits underneath
each of them, both as the path for devices without Apple Intelligence and as the
check on the model.

**The watch is fed, not connected.** It receives flattened snapshots over
WatchConnectivity and never talks to Postgres itself.

Diagrams: [architecture](docs/equitrip-architecture.png) ·
[data flow](docs/equitrip-flow.png) · [user flow](docs/equitrip-userflow.png).

### Invariants

Held in the app and enforced again in RLS.

| | |
|---|---|
| **No money from a model** | Amounts and times are copied from the source text, and a name is used only if it appears there. The model decides what something is, never what it cost. |
| **Settlements need their recipient** | A settlement leaves `.pending` only by the person being paid. The payer may create or withdraw, nothing more. |
| **The audit trail only grows** | No update or delete policy exists for it. Corrections are new rows. It is not the notification list. |
| **One set of arithmetic** | A departure preview asks a hypothetical `Trip` the ordinary share and balance questions, so the preview and the outcome cannot drift apart. |
| **Schema changes are migrations** | Each one is a new numbered file in `supabase/migrations/`. |

<br>

## Getting started

Xcode 26 or later, an iOS 27 simulator or device, and a Mac with Apple
Intelligence available for the on-device features.

```bash
git clone https://github.com/SwastiK-P/Equitrip.git
```

Build the app, the widget extension and the watch app:

```bash
./scripts/build.sh
```

Build, install and launch in the Simulator:

```bash
./scripts/run.sh "iPhone 18 Pro"
```

Both scripts report errors, warnings in changed files, and a single result line;
the full log is written to `build/last-build.log`. Dependencies resolve through
Swift Package Manager. There is no test target — a change is verified by a clean
build, and behaviour by running the app.

**Configuration.** `Services/SupabaseConfig.swift`, `Services/FlightConfig.swift`,
`Services/PhotoConfig.swift` and `Gmail/GmailConfig.swift` hold the project's live
credentials. To run it against your own infrastructure, point them at your
Supabase project, an aviationstack key, an Unsplash application and a Google OAuth
client, then apply `supabase/migrations/` to create the schema and its policies.

<br>

## Project structure

| | |
|---|---|
| `Equitrip/Root/` | `RootTabView` — the tab shell, and the owner of the stores |
| `Equitrip/Stores/` | `TripStore`, `NotificationStore`, `AuditTrail` |
| `Equitrip/Model/` | `Trip`, `ItineraryItem`, `Traveller`, `Money`, `SplitMode`, departures, audit events |
| `Equitrip/Services/` | `SupabaseRepository`, `AuthService`, photography, flights, widget and watch publishing |
| `Equitrip/Intelligence/` | Booking documents to itineraries |
| `Equitrip/Receipts/` | Photographs to reconciled receipts |
| `Equitrip/Gmail/` | Payment email to detected expense |
| `Equitrip/Equi/`, `Chat/` | The assistant, and the per-trip group thread |
| `Equitrip/Intents/` | Siri, Spotlight, Shortcuts and Visual Intelligence |
| `Equitrip/DesignSystem/` | Palette, surfaces, controls, adaptive layout |
| `EquitripShared/` | Compiled into every target |
| `EquitripWidgets/`, `EquitripWatch Watch App/` | Widgets and controls, and the watchOS app |

Every file is named for the type it holds, so `SplitMode` is
`Model/SplitMode.swift`. [`docs/CODEMAP.md`](docs/CODEMAP.md) lists all of them
with their size and purpose, and is generated rather than written.

<br>

## Design

Light mode only. Colour comes from `AppTheme` and `Palette`, cards from
`.cardSurface()`, and every screen sits on `CanvasBackground`. Top bars carry a
soft scroll edge effect; bottom bars carry none. Serif type is reserved for the
name of a trip.

Documentation comments record why something exists — the decision or the bug
behind it — and the first sentence of each becomes that type's entry in the code
map.
