//
//  AppNotification.swift
//  Equitrip
//

import SwiftUI

// MARK: - Notifications

/// The switches in Settings, and what each one covers.
///
/// Grouped by the question being answered rather than by event type: "tell me
/// when money moves" is a thing somebody wants; "tell me about
/// `booking_changed` but not `booking_removed`" is not.
enum NotificationChannel: String, CaseIterable, Identifiable {
    case payments, bookings, people, balances

    var id: String { rawValue }

    var title: String {
        switch self {
        case .payments: "Payments"
        case .bookings: "Bookings"
        case .people: "People"
        case .balances: "Balance changes"
        }
    }

    var detail: String {
        switch self {
        case .payments: "Someone paid, or a payment was disputed"
        case .bookings: "Added, changed or removed"
        case .people: "Joined or left a trip"
        case .balances: "Shares recalculated"
        }
    }

    var symbol: String {
        switch self {
        case .payments: "creditcard"
        case .bookings: "calendar"
        case .people: "person.2"
        case .balances: "arrow.triangle.2.circlepath"
        }
    }

    /// Muting is a per-device preference, not a row on the server: the same
    /// account on a phone and an iPad can reasonably want different noise.
    private var key: String { "notify.\(rawValue)" }

    var isOn: Bool {
        get {
            // Absent means on. A channel nobody has touched should deliver,
            // and `bool(forKey:)` answers false for a key that was never set.
            UserDefaults.standard.object(forKey: key) as? Bool ?? true
        }
        nonmutating set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct AppNotification: Identifiable {
    let id: UUID
    let kind: ActivityEvent.Kind
    let title: String
    let body: String
    let date: Date
    /// Mutable: the point of a notification list is that it stops shouting
    /// once you've read it.
    var isUnread: Bool
    /// Which trip it belongs to, so tapping one can open it.
    var tripID: UUID?
    /// Which booking it's about, when it's about an itinerary item or payment.
    var itemID: UUID?
    /// Which settlement it's about, when it's one of the `settlement*` kinds —
    /// the thing to open is the settlement itself, not just the trip it's on.
    var settlementID: UUID?

    init(
        id: UUID = UUID(),
        kind: ActivityEvent.Kind,
        title: String,
        body: String,
        date: Date = Date(),
        isUnread: Bool = true,
        tripID: UUID? = nil,
        itemID: UUID? = nil,
        settlementID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.date = date
        self.isUnread = isUnread
        self.tripID = tripID
        self.itemID = itemID
        self.settlementID = settlementID
    }

    var time: String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h ago" }
        if seconds < 172_800 { return "Yesterday" }
        return "\(Int(seconds / 86_400))d ago"
    }
}
