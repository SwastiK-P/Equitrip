# Equitrip — Project Index

Native iOS (SwiftUI) group-travel planner + expense ledger. Booking PDFs are read
on-device with Apple Intelligence, verified against source text, then shared as a
live itinerary with five splitting models. Backend is Supabase.

- **Code:** 68 Swift files, ~23,200 LOC, under `Equitrip/`
- **Backend:** 8 SQL migrations under `supabase/migrations/`
- **Narrative doc:** [EQUITRIP_MASTER_DOC.md](../EQUITRIP_MASTER_DOC.md) (639 lines — product, AI pipeline, security, slide material)
- **Diagrams:** `docs/equitrip-architecture.{svg,png}`, `docs/equitrip-flow.{svg,png}`

---

## 1. Entry point & routing

| File | Role |
|---|---|
| [EquitripApp.swift](../Equitrip/EquitripApp.swift) | `@main` scene; forces `.light` color scheme |
| [ContentView.swift](../Equitrip/ContentView.swift) | Route machine: `launching → onboarding → auth → home`; `bindIdentity()` binds display name + `profiles.id` into `CurrentUser` before Home appears |
| [Root/RootTabView.swift](../Equitrip/Root/RootTabView.swift) | `AppTab` tab bar shell |
| [Root/ComingSoonTab.swift](../Equitrip/Root/ComingSoonTab.swift) | Placeholder tab |

## 2. Modules

### Onboarding & Auth
- [Onboarding/OnboardingView.swift](../Equitrip/Onboarding/OnboardingView.swift) — `OnboardingFeature`, `FeatureCard`
- [Onboarding/OnboardingHero.swift](../Equitrip/Onboarding/OnboardingHero.swift) — animated `TripCard` hero
- [Auth/AuthView.swift](../Equitrip/Auth/AuthView.swift) — `AuthMode` (signIn / createAccount), 389 LOC

### Home
- [Home/HomeView.swift](../Equitrip/Home/HomeView.swift) (998) — `CurrentTripCard`, `NewTripCard`, `ProgressTrack`, `ItineraryRow`, `ActivityRow`
- [Home/ProfileSheet.swift](../Equitrip/Home/ProfileSheet.swift) — profile + `PaymentMethodSettingsSheet`, `NotificationSettingsSheet`
- [Home/NotificationsSheet.swift](../Equitrip/Home/NotificationsSheet.swift), [Home/AvatarPickerSheet.swift](../Equitrip/Home/AvatarPickerSheet.swift)

### Intelligence (the differentiator)
| File | Contents |
|---|---|
| [TripExtraction.swift](../Equitrip/Intelligence/TripExtraction.swift) (611) | `TripExtractor`, `ExtractedOverview/DayPlan/Item`, `ExtractedKind`, `PlannedItem`, `PlannedDay`, `IntelligenceAvailability` |
| [ItineraryDocument.swift](../Equitrip/Intelligence/ItineraryDocument.swift) (637) | Document model + `TravelDate` parsing |
| [ItineraryReasoner.swift](../Equitrip/Intelligence/ItineraryReasoner.swift) | Verification / reasoning layer |
| [StructuredRowParser.swift](../Equitrip/Intelligence/StructuredRowParser.swift) | Deterministic row parsing |
| [PDFReader.swift](../Equitrip/Intelligence/PDFReader.swift) | PDF → text |
| [BoardingPassScanner.swift](../Equitrip/Intelligence/BoardingPassScanner.swift) | Vision scan + `BoardingPassReader` (PDF417) |
| [QRScannerView.swift](../Equitrip/Intelligence/QRScannerView.swift) | `QRScanScreen`, `Torch`, `ApertureMask` |
| [QRBurst.swift](../Equitrip/Intelligence/QRBurst.swift) | `QuadCorners` detection burst animation |
| [BurstHaptics.swift](../Equitrip/Intelligence/BurstHaptics.swift), [ActivityIconSuggester.swift](../Equitrip/Intelligence/ActivityIconSuggester.swift) | Haptics; icon inference |

### New-trip flow
`NewTripFlow` (with `StepTrack`, `TripSourceStage`, `DocumentFan`) drives four stages:
[TripBasicsStage](../Equitrip/NewTrip/TripBasicsStage.swift) → [TripImportStage](../Equitrip/NewTrip/TripImportStage.swift) (`LiveField`, `ExtractedRow`) → [TripParticipantsStage](../Equitrip/NewTrip/TripParticipantsStage.swift) → [TripReviewStage](../Equitrip/NewTrip/TripReviewStage.swift).
Plus [ItineraryItemEditor.swift](../Equitrip/NewTrip/ItineraryItemEditor.swift) (1000 LOC), [QuickAddSheet.swift](../Equitrip/NewTrip/QuickAddSheet.swift), [JoinTripFlow.swift](../Equitrip/NewTrip/JoinTripFlow.swift) (invite code / QR join).

### Itinerary
- [TripItineraryView.swift](../Equitrip/Itinerary/TripItineraryView.swift), [TripListView.swift](../Equitrip/Itinerary/TripListView.swift), [TripEditorSheet.swift](../Equitrip/Itinerary/TripEditorSheet.swift)
- [ItineraryItemDetailView.swift](../Equitrip/Itinerary/ItineraryItemDetailView.swift), [TimelineComponents.swift](../Equitrip/Itinerary/TimelineComponents.swift) (`DayHeader`, `TimelineRow`)
- Flights: [FlightTicketCard.swift](../Equitrip/Itinerary/FlightTicketCard.swift), [FlightRouteMap.swift](../Equitrip/Itinerary/FlightRouteMap.swift)
- Maps: [TripsMapView.swift](../Equitrip/Itinerary/TripsMapView.swift) (`TripPinView`, `TripMapCard`)
- Sharing/money: [TripInviteSheet.swift](../Equitrip/Itinerary/TripInviteSheet.swift) (`InviteTicket`, `QRCode`, `BracketShape`), [PaymentSheet.swift](../Equitrip/Itinerary/PaymentSheet.swift), [ReceiptPreview.swift](../Equitrip/Itinerary/ReceiptPreview.swift)

### Expenses & Chat
- [Expenses/TripLedger.swift](../Equitrip/Expenses/TripLedger.swift) — `LedgerRow`, `SpendBreakdown`
- [Chat/ChatService.swift](../Equitrip/Chat/ChatService.swift) — realtime `ChatMessage`, `MessageRow`, `OutgoingMessage`
- [Chat/TripChatView.swift](../Equitrip/Chat/TripChatView.swift) (798) — bubbles, runs, replies, typing indicator

### Model
| File | Key types |
|---|---|
| [TripModels.swift](../Equitrip/Model/TripModels.swift) (1080) | `Money`, `ItineraryKind`, **`SplitMode`**, `PaymentMethod`, `ItineraryItem`, `Trip`, `TripDay`, `FlightDetails`, `TripPhoto`, `ActivityEvent`, `NotificationChannel`, `AppNotification`, `QuickAction` |
| [TripStore.swift](../Equitrip/Model/TripStore.swift) | Observable trip state, env-injected |
| [NotificationStore.swift](../Equitrip/Model/NotificationStore.swift) | Notification state, env-injected |
| [TripDraft.swift](../Equitrip/Model/TripDraft.swift) | Draft → `PlannedItem`/`ExtractedKind` bridging |

### Services
`SupabaseRepository` (758 — row DTOs `TripRow`, `ItemRow`, `ProfileRow`, `MembershipRow`, `ParticipantRow`, `NotificationRow`, `TripMemberRow`, `TripPreviewRow`), `AuthService`, `TravellerDirectory`, `ChatService`, `FlightLookupService` (AviationStack), `PhotoService` (Unsplash/Pexels/Wikimedia), `MediaStore`, `CoverStore`, `CoverTint` (actor), `AppSettings` + `LedgerExport`/`ShareSheet`, and the three config enums `SupabaseConfig`, `FlightConfig`, `PhotoConfig`.

### Design system
[AppTheme.swift](../Equitrip/DesignSystem/AppTheme.swift) (`AppTheme`, `Palette`, `AvatarPalette`), [Components.swift](../Equitrip/DesignSystem/Components.swift) (858 — buttons, `EquitripField`, `CardSurface`, `Hairline`, `SectionHeader`, `TravellerAvatar`, `AvatarStack`, `Traveller`, `CurrentUser`), [GlassForm.swift](../Equitrip/DesignSystem/GlassForm.swift) (`PanelSurface`, `GlassField/Row/Segments`, `FlowLayout`), plus pickers: participant, traveller, currency, location (MapKit), image source, and `DestinationImage`.

## 3. Backend schema (`supabase/migrations/`)

| Migration | Adds |
|---|---|
| `0001_init` | Enums `item_kind`, `member_role`, `split_mode`; tables `profiles`, `trips`, `trip_members`, `itinerary_items`, `item_participants`, `messages`, `notifications`; RLS policies; `is_trip_member()`, `current_profile_id()`, `handle_new_user()` trigger |
| `0002_seed` | Idempotent dummy data (fixed UUIDs, upserts) |
| `0003_message_replies` | Threaded replies + `messages_reply_idx` |
| `0004_traveller_directory` | `profile_contacts`, `find_traveller()`, `invite_traveller()`, `trip_preview()` |
| `0005_payments_and_avatars` | Paid-by / payment method / avatars + balance aggregate |
| `0006_storage_policies` | `storage.objects` insert/read/update policies |
| `0007_itinerary_item_cover` | Per-item cover image |
| `0008_custom_splits` | `custom` exact-amount split; retires "by room" |

Every table is RLS-gated — the shipped publishable key has no privileges of its own.

## 4. Dependencies (SPM)

`supabase-swift 2.55.1` and its transitive deps (swift-asn1, swift-crypto, swift-http-types, swift-clocks, swift-concurrency-extras, xctest-dynamic-overlay). Apple frameworks: SwiftUI, FoundationModels (Apple Intelligence), Vision, PDFKit, MapKit, AVFoundation, CoreHaptics.

## 5. Notes

- **No test target.** There are no `*Tests.swift` files anywhere in the repo.
- **Live API keys are committed in source:** `FlightConfig.aviationStackKey` and `PhotoConfig.unsplashAccessKey` are real values in tracked files. Both are free-tier, but they are public in any clone/push — rotate and move to xcconfig/`Info.plist` if this repo goes public.
- Untracked at index time: `docs/`, and eight tech-logo PNGs at the repo root (`swift.png`, `supabase.png`, `mapkit.png`, `vision.png`, `Foundation.png`, `aviationstack.png`, `unplash.png`, `Swifti.png`) — presentation assets.
