---
paths:
  - "Equitrip/Gmail/**"
---

# Gmail — payment emails → detected expenses

Flow: `GmailExpenseSync` (while a trip is running) → `GmailAPI` (list ids, fetch messages) → `MailMessage`
→ `ExpenseMailReader.read`: `ExpenseMailGate.check` drops promotions, mail with no money in it and money
coming in → on-device model (`MailReading`) → `verify` → `PayeeReader` → `DetectedExpense` in
`DetectedExpenseStore` (a local file on this device) → the user turns it into a ledger entry from
`DetectedExpensesSheet`.

Promises the settings screen makes. Don't weaken them:

- **Only while a trip is under way.** `GmailExpenseSync.window(for:)` returns nil outside a trip, and the
  window is clamped to the trip's own days. No background warming, no token refresh outside it.
- **Read-only.** Scope `gmail.readonly` (`GmailConfig.scope`). Never send, label or delete. OAuth is PKCE
  with no client secret; tokens live in `GmailKeychain`.
- **On-device.** Mail is fetched from Google's API and read on this device only. Its content never goes to
  Supabase. The only thing that does is an entry the user accepts, saved as an ordinary ledger item.
- **The model copies, it doesn't compute.** `MailReading.amount` is a `String` so `verify` can require it
  to appear in the email. A `DetectedExpense` never lands in the ledger without the user's say-so.
- A reject from `ExpenseMailGate` carries its reason. Keep that when adding filters.
