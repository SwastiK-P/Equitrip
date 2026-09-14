//
//  AuditEvent.swift
//  Equitrip
//

import SwiftUI

// MARK: - One recorded change

/// A single field that moved, with both sides of it.
///
/// Rendered strings rather than typed values on purpose. This is a historic
/// record: "₹18,000 → ₹24,000" has to keep saying that in six months' time,
/// after the currency formatter has been changed, after the split modes have
/// been renamed, and after the booking it describes has been deleted. Storing
/// the numbers and formatting them on read means the record of what happened
/// changes when the code does, which is the one thing an audit trail may not
/// do.
struct AuditChange: Codable, Hashable, Identifiable {
    /// What moved, in the words the interface uses. "Amount", "Split", "Paid by".
    let field: String
    /// What it was. Nil when there was nothing there before — a receipt
    /// attached to a booking that had none is an addition, not a replacement.
    let before: String?
    /// What it became. Nil when it was cleared.
    let after: String?

    init(_ field: String, from before: String?, to after: String?) {
        self.field = field
        self.before = before
        self.after = after
    }

    /// Set, rather than changed — the first value a field ever had.
    static func set(_ field: String, _ value: String) -> AuditChange {
        AuditChange(field, from: nil, to: value)
    }

    static func cleared(_ field: String, was: String?) -> AuditChange {
        AuditChange(field, from: was, to: nil)
    }

    var id: String { "\(field)|\(before ?? "—")|\(after ?? "—")" }

    /// The change on one line, the way it reads in the trail.
    var line: String {
        switch (before, after) {
        case let (before?, after?): "\(before) → \(after)"
        case let (nil, after?): "set to \(after)"
        case let (before?, nil): "cleared (was \(before))"
        case (nil, nil): "changed"
        }
    }

    /// Everything in it, for the search index.
    var searchable: String { "\(field) \(before ?? "") \(after ?? "")" }
}

// MARK: - The event

/// One thing that happened on a trip, and who did it.
///
/// The ledger answers "what does this cost and where do I stand". This answers
/// the question that follows it every time somebody disagrees: *why is it that
/// number now*. Every mutation the app makes to a trip lands here — a price
/// edited, a payer named, a split changed, a dispute opened and closed, a
/// transfer claimed and confirmed, somebody invited, somebody gone.
///
/// Append-only, and enforced as such in the database: there is no update
/// policy and no delete policy on `trip_audit_events`, so an entry cannot be
/// tidied up after the fact by the person it embarrasses. A correction is a
/// new entry.
struct AuditEvent: Identifiable, Hashable {

    /// What happened. Raw-valued because it round-trips through a plain `text`
    /// column — the same reasoning as `ActivityEvent.Kind`: an older build
    /// reading a newer trail shows the entry under a fallback glyph rather
    /// than dropping a record of something that definitely happened.
    enum Kind: String, Codable, CaseIterable {
        case tripCreated = "trip_created"
        case tripUpdated = "trip_updated"
        case tripCoverChanged = "trip_cover_changed"
        case tripDeleted = "trip_deleted"

        case expenseAdded = "expense_added"
        case expenseUpdated = "expense_updated"
        case expenseRemoved = "expense_removed"
        case amountChanged = "amount_changed"
        case splitChanged = "split_changed"
        case participantsChanged = "participants_changed"
        case scheduleChanged = "schedule_changed"

        case paymentRecorded = "payment_recorded"
        case paymentChanged = "payment_changed"
        case paymentCleared = "payment_cleared"
        case receiptAttached = "receipt_attached"

        case disputeRaised = "dispute_raised"
        case disputeResolved = "dispute_resolved"

        case settlementRequested = "settlement_requested"
        case settlementConfirmed = "settlement_confirmed"
        case settlementDeclined = "settlement_declined"
        case settlementWithdrawn = "settlement_withdrawn"

        case memberInvited = "member_invited"
        case invitationCancelled = "invitation_cancelled"
        case memberJoined = "member_joined"

        case departureProposed = "departure_proposed"
        case departureConfirmed = "departure_confirmed"
        case departureDeclined = "departure_declined"
        case departureWithdrawn = "departure_withdrawn"
        /// A booking whose price came down because a confirmed departure took
        /// somebody off it. Distinct from `amountChanged`: nobody typed this.
        case repriced

        /// Anything an older build doesn't recognise.
        static func decode(_ raw: String) -> Kind { Kind(rawValue: raw) ?? .expenseUpdated }

        var label: String {
            switch self {
            case .tripCreated: "Trip created"
            case .tripUpdated: "Trip details"
            case .tripCoverChanged: "Cover photo"
            case .tripDeleted: "Trip deleted"
            case .expenseAdded: "Expense added"
            case .expenseUpdated: "Expense edited"
            case .expenseRemoved: "Expense removed"
            case .amountChanged: "Amount changed"
            case .splitChanged: "Split changed"
            case .participantsChanged: "People on expense"
            case .scheduleChanged: "Rescheduled"
            case .paymentRecorded: "Payment recorded"
            case .paymentChanged: "Payment amended"
            case .paymentCleared: "Payment removed"
            case .receiptAttached: "Receipt attached"
            case .disputeRaised: "Dispute raised"
            case .disputeResolved: "Dispute resolved"
            case .settlementRequested: "Settle-up claimed"
            case .settlementConfirmed: "Settle-up confirmed"
            case .settlementDeclined: "Settle-up declined"
            case .settlementWithdrawn: "Settle-up withdrawn"
            case .memberInvited: "Invited"
            case .invitationCancelled: "Invitation withdrawn"
            case .memberJoined: "Joined"
            case .departureProposed: "Exit proposed"
            case .departureConfirmed: "Exit confirmed"
            case .departureDeclined: "Exit declined"
            case .departureWithdrawn: "Exit withdrawn"
            case .repriced: "Repriced"
            }
        }

        var symbol: String {
            switch self {
            case .tripCreated: "sparkles"
            case .tripUpdated: "square.and.pencil"
            case .tripCoverChanged: "photo"
            case .tripDeleted: "trash"
            case .expenseAdded: "plus"
            case .expenseUpdated: "pencil"
            case .expenseRemoved: "trash"
            case .amountChanged: "arrow.up.arrow.down"
            case .splitChanged: "divide"
            case .participantsChanged: "person.2"
            case .scheduleChanged: "calendar"
            case .paymentRecorded: "creditcard.fill"
            case .paymentChanged: "creditcard"
            case .paymentCleared: "creditcard.trianglebadge.exclamationmark"
            case .receiptAttached: "paperclip"
            case .disputeRaised: "exclamationmark.bubble.fill"
            case .disputeResolved: "checkmark.seal.fill"
            case .settlementRequested: "arrow.left.arrow.right"
            case .settlementConfirmed: "checkmark.circle.fill"
            case .settlementDeclined: "xmark.circle.fill"
            case .settlementWithdrawn: "arrow.uturn.backward"
            case .memberInvited: "envelope"
            case .invitationCancelled: "envelope.badge.shield.half.filled"
            case .memberJoined: "person.badge.plus"
            case .departureProposed: "person.badge.clock"
            case .departureConfirmed: "person.badge.minus"
            case .departureDeclined: "hand.raised"
            case .departureWithdrawn: "arrow.uturn.backward"
            case .repriced: "arrow.triangle.2.circlepath"
            }
        }

        var tint: Color {
            switch self {
            case .tripCreated, .tripUpdated, .tripCoverChanged: Palette.blue
            case .tripDeleted, .expenseRemoved, .paymentCleared: AppTheme.danger
            case .expenseAdded: Palette.teal
            case .expenseUpdated, .scheduleChanged: Palette.amber
            case .amountChanged: Palette.amberDeep
            case .splitChanged, .participantsChanged: Palette.indigo
            case .paymentRecorded, .paymentChanged: AppTheme.accent
            case .receiptAttached: Palette.stone
            case .disputeRaised: AppTheme.danger
            case .disputeResolved: AppTheme.positive
            case .settlementRequested: AppTheme.accent
            case .settlementConfirmed: AppTheme.positive
            case .settlementDeclined: AppTheme.danger
            case .settlementWithdrawn: Palette.stone
            case .memberInvited, .memberJoined: Palette.violet
            case .invitationCancelled, .departureDeclined, .departureWithdrawn: Palette.stone
            case .departureProposed: Palette.amber
            case .departureConfirmed: Palette.violetDeep
            case .repriced: Palette.greenDeep
            }
        }

        var category: Category {
            switch self {
            case .amountChanged, .paymentRecorded, .paymentChanged, .paymentCleared,
                 .receiptAttached, .repriced:
                .money
            case .expenseAdded, .expenseUpdated, .expenseRemoved, .splitChanged,
                 .participantsChanged, .scheduleChanged:
                .expenses
            case .disputeRaised, .disputeResolved:
                .disputes
            case .settlementRequested, .settlementConfirmed, .settlementDeclined, .settlementWithdrawn:
                .settlements
            case .memberInvited, .invitationCancelled, .memberJoined,
                 .departureProposed, .departureConfirmed, .departureDeclined, .departureWithdrawn:
                .people
            case .tripCreated, .tripUpdated, .tripCoverChanged, .tripDeleted:
                .trip
            }
        }
    }

    /// How the trail is sliced. Not the same shape as `NotificationChannel` —
    /// that one groups by "do I want to be told"; this one groups by "what am
    /// I trying to check", which is a different question and puts disputes on
    /// their own rather than filed under payments.
    enum Category: String, CaseIterable, Identifiable, Hashable {
        case money, expenses, disputes, settlements, people, trip

        var id: String { rawValue }

        var label: String {
            switch self {
            case .money: "Money"
            case .expenses: "Expenses"
            case .disputes: "Disputes"
            case .settlements: "Settle-ups"
            case .people: "People"
            case .trip: "Trip"
            }
        }

        var symbol: String {
            switch self {
            case .money: "indianrupeesign.circle"
            case .expenses: "list.bullet.rectangle"
            case .disputes: "exclamationmark.bubble"
            case .settlements: "arrow.left.arrow.right"
            case .people: "person.2"
            case .trip: "suitcase"
            }
        }
    }

    let id: UUID
    let tripID: UUID
    let kind: Kind
    /// Who did it. Nil only for a record written before profiles were
    /// resolvable, or one whose author's account has since been deleted —
    /// `actorName` is what the trail actually shows, and it survives either.
    let actorID: UUID?
    /// The actor's name **as it was when they did it**, frozen deliberately.
    /// Somebody who renames themselves does not get to rewrite their history.
    let actorName: String
    /// The booking, settlement, departure or person this is about.
    let subjectID: UUID?
    /// That thing's name at the time. Same freezing, same reason — and it's
    /// what keeps a deleted booking's entries readable.
    let subject: String
    /// The whole event in one sentence, rendered when it happened.
    let summary: String
    /// The field-level diff, when there was one.
    let changes: [AuditChange]
    /// The money involved, when the event is about a figure.
    let amount: Double?
    let currencyCode: String
    let at: Date

    init(
        id: UUID = UUID(),
        tripID: UUID,
        kind: Kind,
        actorID: UUID? = Traveller.you.id,
        actorName: String = Traveller.you.name,
        subjectID: UUID? = nil,
        subject: String = "",
        summary: String,
        changes: [AuditChange] = [],
        amount: Double? = nil,
        currencyCode: String = "INR",
        at: Date = Date()
    ) {
        self.id = id
        self.tripID = tripID
        self.kind = kind
        self.actorID = actorID
        self.actorName = actorName
        self.subjectID = subjectID
        self.subject = subject
        self.summary = summary
        self.changes = changes
        self.amount = amount
        self.currencyCode = currencyCode
        self.at = at
    }

    // MARK: Derived

    var isYours: Bool { actorID == Traveller.you.id }

    /// "You" reads better than your own name in your own trail, and it's how
    /// every other screen in the app refers to you.
    var actorLabel: String { isYours ? "You" : actorName }

    var amountLabel: String? {
        amount.map { Money.format($0, code: currencyCode) }
    }

    /// The exact moment, spelled out. An audit entry that only says "2h ago"
    /// is useless the moment somebody needs to line it up against a bank
    /// statement, so the precise stamp is always available — to the second,
    /// because two edits a minute apart are exactly the pair someone is
    /// trying to tell apart.
    var timestamp: String {
        DateFormatter.cached("d MMM yyyy, h:mm:ss a").string(from: at)
    }

    var clock: String { DateFormatter.cached("h:mm a").string(from: at) }

    var relative: String {
        let seconds = Date().timeIntervalSince(at)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h ago" }
        if seconds < 604_800 { return "\(Int(seconds / 86_400))d ago" }
        return DateFormatter.cached("d MMM").string(from: at)
    }

    var day: Date { Calendar.current.startOfDay(for: at) }

    /// Everything a search should be able to reach: what happened, to what, by
    /// whom, for how much, on what date — including the spelled-out date, so
    /// typing "12 Mar" or "2026" finds the day rather than nothing.
    var searchIndex: String {
        (
            [summary, subject, actorLabel, actorName, kind.label, kind.category.label, timestamp]
                + changes.map(\.searchable)
                + [amountLabel].compactMap { $0 }
        )
        .joined(separator: " ")
        .lowercased()
    }

    func matches(_ query: String) -> Bool {
        let terms = query
            .lowercased()
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !terms.isEmpty else { return true }

        // Every term has to appear somewhere — "kim dispute" means entries
        // about Kim *and* about a dispute, not the union of the two, which on
        // a busy trip is the whole trail.
        let index = searchIndex
        return terms.allSatisfy { index.contains($0) }
    }
}

// MARK: - Day grouping

/// One day of the trail, newest first within it.
struct AuditDay: Identifiable {
    let date: Date
    let events: [AuditEvent]

    var id: Date { date }

    var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return DateFormatter.cached("EEEE d MMMM").string(from: date)
        }
        return DateFormatter.cached("EEEE d MMMM yyyy").string(from: date)
    }

    var caption: String { events.count.pluralised("change") }
}
