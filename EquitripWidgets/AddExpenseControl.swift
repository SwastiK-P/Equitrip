//
//  AddExpenseControl.swift
//  EquitripWidgets
//

import AppIntents
import SwiftUI
import WidgetKit

/// "I just paid for that" as a single press, from Control Centre, the Lock
/// Screen, or the Action button.
///
/// One `ControlWidget` covers all three — they are the same slot to the
/// system, and offering the control anywhere offers it everywhere. This is the
/// moment the app is worst at: the expense happens at a table with the bill in
/// somebody's hand, and by the time you have unlocked the phone, found
/// Equitrip, waited for the trip list to sync and tapped through to the right
/// trip, the amount has already stopped being the thing you were thinking
/// about. From the lock screen it is one press and a keypad.
struct AddExpenseControl: ControlWidget {
    static let kind = "EquitripAddExpense"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: AddExpenseIntent()) {
                // A plus, not a rupee sign. The glyph has to say what the
                // press *does* rather than what the app is about — Control
                // Centre is a wall of icons with no labels on it until you
                // look, and a currency mark there reads as "money", which is
                // every button Equitrip could ever have. The plus reads as
                // "add", which is the only thing this one does.
                Label("Add expense", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Add expense")
        .description("Log what you just paid for, straight onto the trip you're on.")
    }
}
