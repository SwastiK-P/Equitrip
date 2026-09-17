//
//  ActivityEvent.swift
//  Equitrip
//

import SwiftUI

// MARK: - Ledger activity

struct ActivityEvent: Identifiable {
    /// Raw-valued so it round-trips through `notifications.kind`, which is a
    /// plain text column rather than an enum type — the set of things worth
    /// telling someone about grows faster than a migration can keep up with.
    ///
    /// That column being plain text is also why new cases can be added without
    /// a migration: `NotificationRow.asNotification` falls back to `.booking`
    /// for anything it doesn't recognise, so an older build reading a newer
    /// event shows it with the wrong glyph rather than dropping it.
    enum Kind: String, CaseIterable {
        case payment, recalculation, refund, joined, booking
        /// Somebody has asked to leave a trip that's already running. Not a
        /// fact yet — it changes what other people owe, so it waits on an
        /// answer the way a settlement does.
        /// Somebody has been asked to join a trip. Addressed to them alone —
        /// nothing happens to anybody's ledger until they accept.
        case invited
        case departureRequested = "departure_requested"
        /// The group agreed. Their side of the ledger is closed.
        case left
        /// A booking's details moved under people who'd already planned round
        /// them — a time, a price, who's on it.
        case bookingChanged = "booking_changed"
        /// A booking that no longer exists. Distinct from a refund: the money
        /// may never have been spent, but the plan definitely changed.
        case bookingRemoved = "booking_removed"
        /// Someone agreed a payment happened as recorded.
        case confirmed
        /// Someone said it didn't. The whole point of `confirmed` existing.
        case disputed
        /// Somebody marked a direct settlement as paid, and it's waiting on
        /// the person who received it to say so too.
        case settlementRequested = "settlement_requested"
        /// The recipient agreed — the balance it covered is actually gone now.
        case settlementConfirmed = "settlement_confirmed"
        /// The recipient said the money never arrived. Distinct from
        /// `disputed`: that one questions a figure, this one questions
        /// whether a transfer happened at all.
        case settlementDeclined = "settlement_declined"

        var symbol: String {
            switch self {
            case .payment: "arrow.up.right"
            case .recalculation: "arrow.triangle.2.circlepath"
            case .refund: "arrow.uturn.backward"
            case .joined: "person.badge.plus"
            case .invited: "envelope.badge"
            case .departureRequested: "person.badge.clock"
            case .left: "person.badge.minus"
            case .booking: "checkmark"
            case .bookingChanged: "pencil"
            case .bookingRemoved: "trash"
            case .confirmed: "checkmark.seal.fill"
            case .disputed: "exclamationmark.bubble.fill"
            case .settlementRequested: "arrow.left.arrow.right"
            case .settlementConfirmed: "checkmark"
            case .settlementDeclined: "xmark"
            }
        }

        var tint: Color {
            switch self {
            case .payment: AppTheme.accent
            case .recalculation: Palette.amber
            case .refund: AppTheme.positive
            case .joined: Palette.violet
            case .invited: AppTheme.accent
            case .departureRequested: Palette.amber
            case .left: Palette.violet
            case .booking: Palette.blue
            case .bookingChanged: Palette.amber
            case .bookingRemoved: AppTheme.danger
            case .confirmed: AppTheme.positive
            case .disputed: AppTheme.danger
            case .settlementRequested: AppTheme.accent
            case .settlementConfirmed: AppTheme.positive
            case .settlementDeclined: AppTheme.danger
            }
        }

        /// Which switch in Settings governs this event. Several kinds share
        /// one — nobody wants four separate toggles for "a booking changed".
        var channel: NotificationChannel {
            switch self {
            case .payment, .refund, .confirmed, .disputed,
                 .settlementRequested, .settlementConfirmed, .settlementDeclined:
                .payments
            case .booking, .bookingChanged, .bookingRemoved: .bookings
            case .joined, .invited, .departureRequested, .left: .people
            case .recalculation: .balances
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let actor: String
    let detail: String
    let context: String
    let amount: String?
    let amountTone: Color
}
