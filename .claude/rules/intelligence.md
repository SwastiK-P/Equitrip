---
paths:
  - "Equitrip/Intelligence/**"
  - "Equitrip/NewTrip/TripImportStage.swift"
  - "Equitrip/NewTrip/TripReviewStage.swift"
  - "Equitrip/NewTrip/ItineraryIssueCard.swift"
---

# Intelligence — booking PDF → itinerary

Pipeline (driven by `NewTrip/TripImportStage` then `NewTrip/TripReviewStage`):

1. `PDFReader.text(at:)` — PDF to plain text.
2. `ItineraryDocument.parse` — deterministic structure: header facts, dated day sections, and the
   appendix (cost tables) that must never become bookings. Dates via `TravelDate`.
3. `TripExtractor.extract` — one `LanguageModelSession` per day with small `@Generable` schemas
   (`ExtractedOverview`, `ExtractedDayPlan`), 3 days at a time. `validate` lines each item up with its
   source row and takes amount and time from the text. A day that throws or validates empty falls back to
   `StructuredRowParser`; so does the whole document without Apple Intelligence (`usedFallback`).
4. `ItineraryReasoner.refine` — deterministic tidy: reclassify, dedupe, order, drop non-bookings.
5. Review: `ItineraryConsistency.check` (clock arithmetic: clashes, gaps, duplicates) and
   `ItineraryInspector.stream` (model: is this place in the trip's cities?) → `ItineraryIssue` →
   `NewTrip/ItineraryIssueCard`.

Rules

- The model classifies and copies; Swift writes. Schemas never ask for dates, prices or user-facing
  sentences. Traveller names survive only if they appear in the document (`verified(_:)`).
- Deterministic passes only narrow model output. They never add a booking, price or time.
- Domain knowledge ("airport transfer isn't a flight") goes in `ItineraryReasoner` rules, not prompt text.
- The on-device context window is a few thousand tokens: one day per prompt, small instructions.
- Everything must still work with no model (Simulator, ineligible devices) through `StructuredRowParser`.
