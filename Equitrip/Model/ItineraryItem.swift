//
//  ItineraryItem.swift
//  Equitrip
//

import SwiftUI

// MARK: - Itinerary item

struct ItineraryItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var vendor: String
    var kind: ItineraryKind
    var date: Date
    /// Nil when the document only gave a day, which is common for stays.
    var time: Date?
    var cost: Double
    var split: SplitMode
    /// Who is actually on this. The subset is the point — a trip total
    /// divided by heads would be wrong for anything but `.equal`.
    var participantIDs: Set<UUID>
    /// What each person owes, when `split` is `.custom`. Ignored otherwise.
    ///
    /// Stored per booking rather than derived, because it can't be derived:
    /// "Ravi had the lobster" is information the app has no way of working out
    /// from a total and a headcount. Kept as a dictionary so a participant
    /// added later simply has no entry yet, rather than silently shifting
    /// everybody else's figure.
    var customShares: [UUID: Double]
    /// What to search for a photo of this place, when it deserves one.
    var photoQuery: String?
    /// A photo someone actually picked for this booking — from Unsplash or
    /// their own library — as opposed to `photoQuery`'s auto-resolved guess.
    var cover: TripPhoto?
    /// A better-fitting glyph than the category's default, chosen on-device
    /// from the title. Nil means "use the category's".
    var suggestedSymbol: String?
    /// Live tracking data, when this is a flight and someone's looked it up.
    var flight: FlightDetails?
    /// Who actually handed over the money. Nil means nobody has said yet, and
    /// the cost sits on the trip without sitting on anybody in particular —
    /// which is exactly the state a group ledger has to be able to represent,
    /// because "we'll sort it later" is how most bookings start.
    var paidByID: UUID?
    /// How they paid. Only meaningful alongside `paidByID`.
    var paymentMethod: PaymentMethod?
    /// The confirmation, when the payment was one that produces one.
    var receiptURL: URL?
    /// Who added it. Worth keeping: when a price looks wrong, the first useful
    /// question is who entered it.
    var createdByID: UUID?
    var createdAt: Date
    /// True when someone has disputed the payment recorded on this item.
    var isDisputed: Bool
    /// Who raised the dispute.
    var disputedByID: UUID?
    /// When the dispute was opened.
    var disputedAt: Date?
    /// Why it was disputed (e.g. amount mismatch, wrong payer).
    var disputeReason: String?
    /// When the dispute was marked resolved.
    var disputeResolvedAt: Date?
    /// Who marked it resolved.
    var disputeResolvedByID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        vendor: String = "",
        kind: ItineraryKind = .other,
        date: Date,
        time: Date? = nil,
        cost: Double = 0,
        split: SplitMode? = nil,
        participantIDs: Set<UUID> = [],
        customShares: [UUID: Double] = [:],
        photoQuery: String? = nil,
        cover: TripPhoto? = nil,
        suggestedSymbol: String? = nil,
        flight: FlightDetails? = nil,
        paidByID: UUID? = nil,
        paymentMethod: PaymentMethod? = nil,
        receiptURL: URL? = nil,
        createdByID: UUID? = nil,
        createdAt: Date = Date(),
        isDisputed: Bool = false,
        disputedByID: UUID? = nil,
        disputedAt: Date? = nil,
        disputeReason: String? = nil,
        disputeResolvedAt: Date? = nil,
        disputeResolvedByID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.vendor = vendor
        self.kind = kind
        self.date = date
        self.time = time
        self.cost = cost
        self.split = split ?? kind.defaultSplit
        self.participantIDs = participantIDs
        self.customShares = customShares
        self.photoQuery = photoQuery
        self.cover = cover
        self.suggestedSymbol = suggestedSymbol
        self.flight = flight
        self.paidByID = paidByID
        self.paymentMethod = paymentMethod
        self.receiptURL = receiptURL
        self.createdByID = createdByID ?? Traveller.you.id
        self.createdAt = createdAt
        self.isDisputed = isDisputed
        self.disputedByID = disputedByID
        self.disputedAt = disputedAt
        self.disputeReason = disputeReason
        self.disputeResolvedAt = disputeResolvedAt
        self.disputeResolvedByID = disputeResolvedByID
    }

    // Equality is memberwise on purpose — do not narrow it back to `id`.
    //
    // `@State` skips invalidating the view when the value it is handed
    // compares equal to the one it already holds. An `==` that only looked at
    // `id` made every in-place edit invisible: the booking editor's category,
    // split and participant taps mutated `draft`, SwiftUI saw "same item" and
    // never redrew, so the tap registered (haptic and all) with nothing to
    // show for it until some unrelated change forced a pass. Identity
    // comparisons are spelled `$0.id == other.id` at the call sites that want
    // them, which is all of them.

    /// The glyph to draw. A suggestion beats the category default.
    var symbol: String { suggestedSymbol ?? kind.symbol }

    /// The vendor, or nil when there isn't one.
    ///
    /// `vendor` is a non-optional string that is very often blank, and half of
    /// it is whitespace rather than truly empty — an editor field somebody
    /// tabbed through, an import that found a label and no value. Every call
    /// site checking `!vendor.isEmpty` therefore left a blank line on screen
    /// some of the time, so the check lives here once instead.
    var vendorName: String? {
        let trimmed = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Start of the day the item falls on — the timeline's grouping key.
    var day: Date { Calendar.current.startOfDay(for: date) }

    var timeLabel: String? {
        guard let time else { return nil }
        return Self.timeFormatter.string(from: time)
    }

    /// Split into value and meridiem so the timeline can stack them.
    var clock: (value: String, meridiem: String)? {
        guard let label = timeLabel else { return nil }
        let parts = label.split(separator: " ")
        guard parts.count == 2 else { return (label, "") }
        return (String(parts[0]), String(parts[1]))
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        return f
    }()
}
