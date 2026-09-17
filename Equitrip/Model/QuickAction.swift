//
//  QuickAction.swift
//  Equitrip
//

import SwiftUI

// MARK: - Quick actions

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
}

extension QuickAction {
    static let all: [QuickAction] = [
        .init(title: "Expense", symbol: "plus"),
        // Receipt, not Payment: "Payment" only ever opened the Settle tab,
        // which the hero's own Settle up button already does. A receipt is
        // the thing in someone's hand at the table.
        .init(title: "Receipt", symbol: "doc.text.viewfinder"),
        .init(title: "New trip", symbol: "suitcase"),
        // Chat, not Invite: inviting is a once-per-trip act that lives on the
        // trip itself, while the conversation is the thing you reach for daily.
        .init(title: "Chat", symbol: "message")
    ]
}
