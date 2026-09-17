---
paths:
  - "EquitripShared/**"
  - "EquitripWidgets/**"
  - "EquitripWatch Watch App/**"
  - "Equitrip/Services/WidgetPublisher.swift"
  - "Equitrip/Services/WatchBridge.swift"
---

# EquitripShared

Compiled into **all three targets** by folder sync, minus the membership exceptions in
`project.pbxproj`: the watch skips `AddExpenseIntent`/`OpenEquiIntent`, the widgets skip `WatchMessage`.
A new file here builds everywhere, so it must compile for iOS app, WidgetKit extension and watchOS.

- The widgets target has no default `MainActor` isolation, while the app and watch do. Mark shared
  types and helpers `nonisolated` (see `EquitripSnapshot`) so they behave the same in every target.
- Imports stay at Foundation / SwiftUI / AppIntents. Nothing app-only (Supabase, FoundationModels, app
  views): widgets and watch never sign in.
- `EquitripSnapshot` is the only data contract with widgets/watch: pre-formatted strings plus numbers,
  written by the app's `WidgetPublisher`, read through `SharedStore` (app group).
- `Brand` holds the palette literals; `AppTheme` aliases them. Change colours in `Brand`.
- After changing anything here, build with `scripts/build.sh` (the `Equitrip` scheme builds all targets).
