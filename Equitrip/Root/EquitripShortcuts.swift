//
//  EquitripShortcuts.swift
//  Equitrip
//

import AppIntents

/// The sentences Siri knows before anyone has set anything up.
///
/// The Control Centre button and this are not the same thing, which is easy to
/// miss: a `ControlWidget` only ever appears in the controls gallery, and an
/// intent that no `AppShortcutsProvider` names is invisible everywhere else —
/// no entry under a long press on the app icon, nothing in Spotlight, nothing
/// to say to Siri. The build says so out loud ("No AppShortcuts found") and it
/// is the reason the quick action was missing from every surface except the
/// one the control put it on.
///
/// The schema intents — adding and changing bookings, sending messages to a
/// trip's chat — aren't listed here and don't need to be: Apple Intelligence
/// matches those by meaning. These are the actions only this app has, so they
/// need their words spelled out. The system allows ten; phrases that name a
/// trip are refreshed from `SpotlightIndex` whenever the trips change, which
/// is what teaches Siri that "Goa" is a trip.
///
/// Every phrase has to contain the app name token, or it's silently dropped.
struct EquitripShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add an expense to \(.applicationName)",
                "Log a payment in \(.applicationName)",
                "Split a bill in \(.applicationName)",
                "Log an expense on \(\.$trip) in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "indianrupeesign.circle"
        )

        AppShortcut(
            intent: TripBalanceIntent(),
            phrases: [
                "Where do I stand in \(.applicationName)",
                "What do I owe in \(.applicationName)",
                "Who owes me in \(.applicationName)",
                "Where do I stand on \(\.$trip) in \(.applicationName)",
                "What do I owe on \(\.$trip) in \(.applicationName)"
            ],
            shortTitle: "My Balance",
            systemImageName: "arrow.left.arrow.right"
        )

        AppShortcut(
            intent: WhatsNextIntent(),
            phrases: [
                "What's next in \(.applicationName)",
                "What's next on my trip in \(.applicationName)",
                "What's next on \(\.$trip) in \(.applicationName)",
                "What's the plan in \(.applicationName)"
            ],
            shortTitle: "What's Next",
            systemImageName: "calendar.day.timeline.left"
        )

        AppShortcut(
            intent: AskEquiQuestionIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Ask Equi in \(.applicationName)",
                "Ask \(.applicationName)"
            ],
            shortTitle: "Ask Equi",
            // Siri and Spotlight take a system name only, so the app's own
            // glyph cannot travel here — this is the nearest system symbol
            // for "the assistant".
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenTripIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show \(\.$target) in \(.applicationName)",
                "Open my trip in \(.applicationName)"
            ],
            shortTitle: "Open Trip",
            systemImageName: "suitcase.rolling"
        )

        AppShortcut(
            intent: OpenTripChatIntent(),
            phrases: [
                "Open the \(\.$target) chat in \(.applicationName)",
                "Open the trip chat in \(.applicationName)"
            ],
            shortTitle: "Trip Chat",
            systemImageName: "bubble.left.and.bubble.right"
        )

        // Opening the sheet is still the fastest path when the numbers are
        // easier typed than said — the Control Centre button's intent.
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Open quick add in \(.applicationName)",
                "Type an expense in \(.applicationName)"
            ],
            shortTitle: "Quick Add",
            systemImageName: "plus.circle.fill"
        )
    }
}
