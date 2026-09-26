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
/// trip are refreshed from `SpotlightIndex` whenever the trip names change,
/// which is what teaches Siri that "Goa" is a trip.
///
/// Every phrase has to contain the app name token, or it's silently dropped.
struct EquitripShortcuts: AppShortcutsProvider {
    // Most-used first: the order is what Spotlight and the Shortcuts app show
    // until they've learned what this person actually reaches for. Phrases
    // are short and plain on purpose — the first set had sentences like
    // "Where do I stand in Equitrip", which nobody says, so nobody's words
    // matched them.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add an expense in \(.applicationName)",
                "Add an expense to \(.applicationName)",
                "New \(.applicationName) expense",
                "Split a bill in \(.applicationName)",
                "Log a payment in \(.applicationName)",
                "Log an expense on \(\.$trip) in \(.applicationName)",
                "Add an expense to \(\.$trip) in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: TripBalanceIntent(),
            phrases: [
                "What do I owe in \(.applicationName)",
                "Who owes me in \(.applicationName)",
                "Check my balance in \(.applicationName)",
                "Show my \(.applicationName) balance",
                "\(.applicationName) balance",
                "Settle up in \(.applicationName)",
                "Where do I stand in \(.applicationName)",
                "What do I owe on \(\.$trip) in \(.applicationName)",
                "Show my balance for \(\.$trip) in \(.applicationName)"
            ],
            shortTitle: "Balance",
            systemImageName: "arrow.left.arrow.right"
        )

        AppShortcut(
            intent: WhatsNextIntent(),
            phrases: [
                "What's next in \(.applicationName)",
                "What's next on my trip in \(.applicationName)",
                "What's on today in \(.applicationName)",
                "Show my plan in \(.applicationName)",
                "What's my next booking in \(.applicationName)",
                "What's next on \(\.$trip) in \(.applicationName)"
            ],
            shortTitle: "What's Next",
            systemImageName: "calendar.day.timeline.left"
        )

        AppShortcut(
            intent: PaymentsWaitingIntent(),
            phrases: [
                "Check payments in \(.applicationName)",
                "Did anyone pay me in \(.applicationName)",
                "Confirm payments in \(.applicationName)",
                "Who paid me in \(.applicationName)"
            ],
            shortTitle: "Check Payments",
            systemImageName: "checkmark.seal"
        )

        AppShortcut(
            intent: TripCountdownIntent(),
            phrases: [
                "How long until my trip in \(.applicationName)",
                "Trip countdown in \(.applicationName)",
                "\(.applicationName) countdown",
                "How long until \(\.$trip) in \(.applicationName)",
                "Countdown to \(\.$trip) in \(.applicationName)"
            ],
            shortTitle: "Countdown",
            systemImageName: "hourglass"
        )

        // A shortcut phrase can't carry a free-form question, so Siri asks
        // for it after — "Ask Equitrip who paid for the villa" is two turns.
        AppShortcut(
            intent: AskEquiQuestionIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Ask Equi in \(.applicationName)",
                "Ask \(.applicationName) a question"
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
            systemImageName: "square.and.pencil"
        )
    }
}
