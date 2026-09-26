---
paths:
  - "Equitrip/Intents/**"
  - "Equitrip/Root/EquitripShortcuts.swift"
  - "Equitrip/Home/SiriSettingsSheet.swift"
---

# Intents — Siri, Shortcuts, Spotlight

Every answer an intent gives is a **snippet intent**, not a view: the parent returns `ShowsSnippetIntent`
(`.result(value:dialog:snippetIntent:)`), and a `SnippetIntent` in `Intents/Snippets/` reads the store
live and draws the card. The system runs it again after any button on the card, so `perform()` has no
side effects and uses `IntentStores.store(fresh: false)`. Keep the parent's `ReturnsValue` type unchanged,
because saved shortcuts depend on it.

- **Cards:** built from `SnippetCard` and the pieces in `SnippetChrome.swift`. Tint and photo come from
  `SnippetArtwork.look(for:)`: cover colour from `CoverTint`'s disk cache, made readable by `SnippetTint`.
  Views take plain value models (`…Model`), which keeps them previewable and lets `SiriSettingsSheet` and
  `EquiAnswerSnippetIntent` reuse them. Keep each card ≤340pt tall.
- **Text size:** Siri draws snippet text about one Dynamic Type size up. Chips, buttons and eyebrows use
  fixed sizes; rows with a long name put the name on its own truncating line.
- **Images:** no `AsyncImage` in a card, since the system renders it and nothing loads later. Pass
  `Image`s in, and use bundled avatar artwork only.
- **Buttons:** `Button(intent:)` with the small internal intents (`OpenFromSnippetIntent`,
  `RespondToSettlementIntent`, `SetDraft…`, `UndoLoggedExpenseIntent`, `OpenInMapsIntent`). They take
  **String** ids and set `isDiscoverable = false`. A write awaits `store.settleWrites()` before it returns.
- **Confirmations:** `requestConfirmation(actionName:dialog:snippetIntent:)`. Mutable choices live in a
  `@MainActor` in-memory book (`ExpenseDraftBook`), and the intent reads the confirmed values back from it.
- **Phrases:** `EquitripShortcuts` allows at most 10 shortcuts, and every phrase needs `.applicationName`.
  Only App Entity/App Enum parameters can appear in a phrase, never free text or amounts.
  `SiriSettingsSheet` lists exact registered phrases; schema-only sentences go under "With Apple
  Intelligence".
- **Messages domain:** the "Message Sending" use case needs both `sendMessage` and `draftMessage`
  (`DraftChatMessageIntent`). The build warns if either is missing.
