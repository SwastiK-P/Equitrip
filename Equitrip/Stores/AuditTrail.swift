//
//  AuditTrail.swift
//  Equitrip
//

import SwiftUI

/// Every change ever made to a trip, and who made it.
///
/// Separate from `NotificationStore` because the two answer different
/// questions and are wrong for each other's job. A notification is addressed
/// to *somebody*, is filtered by whether they asked to hear about it, gets
/// marked read and is fair game to mute — none of which an auditor may do. The
/// trail is addressed to nobody, hides nothing, is never read or unread, and
/// is append-only in the database as well as here. If the two disagree about
/// what happened, this one is the record.
///
/// Loaded per trip and cached per trip: a trail is only ever read from inside
/// a trip, and pulling everyone's history at launch would be a lot of rows
/// nobody has asked to see.
@MainActor
@Observable
final class AuditTrail {

    /// Newest first, per trip.
    private(set) var events: [UUID: [AuditEvent]] = [:]
    private(set) var loading: Set<UUID> = []
    /// Trips whose trail has come back from the server at least once. An empty
    /// array and "we haven't asked yet" look identical otherwise, and the
    /// sheet says something different for each.
    private(set) var loaded: Set<UUID> = []

    init() {}

    func events(for tripID: UUID) -> [AuditEvent] { events[tripID] ?? [] }

    func count(for tripID: UUID) -> Int { events(for: tripID).count }

    func latest(for tripID: UUID) -> AuditEvent? { events(for: tripID).first }

    func isLoading(_ tripID: UUID) -> Bool { loading.contains(tripID) }

    func hasLoaded(_ tripID: UUID) -> Bool { loaded.contains(tripID) }

    // MARK: - Loading

    /// Pulls a trip's trail. Merges rather than replaces, so an entry recorded
    /// on this device a moment ago doesn't vanish and come back while its
    /// write is still in flight.
    func load(_ tripID: UUID) async {
        guard !loading.contains(tripID) else { return }
        loading.insert(tripID)
        defer { loading.remove(tripID) }

        guard let remote = try? await SupabaseRepository.shared.loadAuditEvents(tripID: tripID) else { return }
        merge(remote, into: tripID)
        loaded.insert(tripID)
    }

    private func merge(_ remote: [AuditEvent], into tripID: UUID) {
        // The server's copy wins on id collisions — it's the one that actually
        // persisted, and a local optimistic entry is only ever a preview of it.
        var byID = Dictionary(events(for: tripID).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for event in remote { byID[event.id] = event }
        events[tripID] = byID.values.sorted { $0.at > $1.at }
    }

    // MARK: - Recording

    /// Files an entry: on screen at once, on the server as soon as it will
    /// take it.
    ///
    /// A failed write is deliberately *not* rolled back. Unlike a balance, an
    /// audit entry that didn't reach the server is still a true statement
    /// about what this device did, and dropping it would leave the trail
    /// claiming a change happened by itself. The next `load` reconciles.
    func record(_ event: AuditEvent) {
        events[event.tripID, default: []].insert(event, at: 0)
        events[event.tripID]?.sort { $0.at > $1.at }

        Task { await SupabaseRepository.shared.recordAuditEvent(event) }
    }

    /// Several entries from one action, in the order they happened.
    private func record(_ batch: [AuditEvent]) {
        for event in batch { record(event) }
    }

    // MARK: - Trip

    func tripCreated(_ trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .tripCreated,
                subjectID: trip.id,
                subject: trip.title,
                summary: "Created \(trip.title)",
                changes: [
                    .set("Destination", trip.destination),
                    .set("Dates", trip.dateRange),
                    .set("Currency", trip.currencyCode),
                    .set("Travellers", trip.travellers.map(\.name).sorted().joined(separator: ", "))
                ].filter { ($0.after ?? "").isEmpty == false },
                amount: trip.projectedCost > 0 ? trip.projectedCost : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    func tripUpdated(from old: Trip, to new: Trip) {
        var changes: [AuditChange] = []
        if old.title != new.title { changes.append(AuditChange("Name", from: old.title, to: new.title)) }
        if old.destination != new.destination {
            changes.append(AuditChange("Destination", from: old.destination, to: new.destination))
        }
        if old.dateRange != new.dateRange {
            changes.append(AuditChange("Dates", from: old.dateRange, to: new.dateRange))
        }
        if old.currencyCode != new.currencyCode {
            changes.append(AuditChange("Currency", from: old.currencyCode, to: new.currencyCode))
        }
        if old.organiserIDs != new.organiserIDs {
            changes.append(
                AuditChange(
                    "Organisers",
                    from: names(old.organiserIDs, in: old),
                    to: names(new.organiserIDs, in: new)
                )
            )
        }
        guard !changes.isEmpty else { return }

        record(
            AuditEvent(
                tripID: new.id,
                kind: .tripUpdated,
                subjectID: new.id,
                subject: new.title,
                summary: "Edited the trip details",
                changes: changes,
                currencyCode: new.currencyCode
            )
        )
    }

    func coverChanged(in trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .tripCoverChanged,
                subjectID: trip.id,
                subject: trip.title,
                summary: "Changed the cover photo",
                currencyCode: trip.currencyCode
            )
        )
    }

    func tripDeleted(_ trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .tripDeleted,
                subjectID: trip.id,
                subject: trip.title,
                summary: "Deleted \(trip.title)",
                amount: trip.projectedCost > 0 ? trip.projectedCost : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    // MARK: - Expenses

    func expenseAdded(_ item: ItineraryItem, to trip: Trip) {
        var changes: [AuditChange] = [
            .set("Category", item.kind.label),
            .set("Date", DateFormatter.cached("d MMM yyyy").string(from: item.date))
        ]
        if item.cost > 0 {
            changes.insert(.set("Amount", Money.format(item.cost, code: trip.currencyCode)), at: 0)
            changes.append(.set("Split", item.split.label))
        }
        if let payer = name(item.paidByID, in: trip) {
            changes.append(.set("Paid by", payer))
        }

        record(
            AuditEvent(
                tripID: trip.id,
                kind: .expenseAdded,
                subjectID: item.id,
                subject: item.title,
                summary: item.cost > 0
                    ? "Added \(item.title) for \(Money.format(item.cost, code: trip.currencyCode))"
                    : "Added \(item.title)",
                changes: changes,
                amount: item.cost > 0 ? item.cost : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    func expenseRemoved(_ item: ItineraryItem, from trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .expenseRemoved,
                subjectID: item.id,
                subject: item.title,
                summary: item.cost > 0
                    ? "Removed \(item.title), which was \(Money.format(item.cost, code: trip.currencyCode))"
                    : "Removed \(item.title)",
                changes: [
                    .cleared("Amount", was: item.cost > 0 ? Money.format(item.cost, code: trip.currencyCode) : nil),
                    .cleared("Paid by", was: name(item.paidByID, in: trip))
                ].filter { $0.before != nil },
                amount: item.cost > 0 ? item.cost : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    /// One edit, one entry — with everything that moved inside it.
    ///
    /// Deliberately not one entry per field. An edit is a thing a person did
    /// at a moment; splitting it into five rows makes the trail longer without
    /// making it truer, and it becomes impossible to see that the price went
    /// up *and* two people came off in the same stroke. The `kind` picks out
    /// the most consequential of the changes so the filters and the glyph
    /// lead with it, and the rest travel alongside.
    func expenseChanged(from old: ItineraryItem, to new: ItineraryItem, in trip: Trip) {
        let currency = trip.currencyCode
        var changes: [AuditChange] = []

        if old.title != new.title { changes.append(AuditChange("Name", from: old.title, to: new.title)) }
        if old.vendor != new.vendor {
            changes.append(AuditChange("Vendor", from: old.vendorName, to: new.vendorName))
        }
        if old.kind != new.kind {
            changes.append(AuditChange("Category", from: old.kind.label, to: new.kind.label))
        }
        if old.cost != new.cost {
            changes.append(
                AuditChange(
                    "Amount",
                    from: Money.format(old.cost, code: currency),
                    to: Money.format(new.cost, code: currency)
                )
            )
        }
        if old.split != new.split {
            changes.append(AuditChange("Split", from: old.split.label, to: new.split.label))
        }
        if old.customShares != new.customShares, new.split.isCustom || old.split.isCustom {
            changes.append(
                AuditChange(
                    "Exact shares",
                    from: shareSummary(old.customShares, in: trip),
                    to: shareSummary(new.customShares, in: trip)
                )
            )
        }
        if old.participantIDs != new.participantIDs {
            let added = new.participantIDs.subtracting(old.participantIDs)
            let dropped = old.participantIDs.subtracting(new.participantIDs)
            if !added.isEmpty { changes.append(.set("Added", names(added, in: trip))) }
            if !dropped.isEmpty { changes.append(.cleared("Removed", was: names(dropped, in: trip))) }
        }
        if !Calendar.current.isDate(old.date, inSameDayAs: new.date) {
            changes.append(
                AuditChange(
                    "Date",
                    from: DateFormatter.cached("d MMM yyyy").string(from: old.date),
                    to: DateFormatter.cached("d MMM yyyy").string(from: new.date)
                )
            )
        }
        if old.time != new.time {
            changes.append(AuditChange("Time", from: old.timeLabel, to: new.timeLabel))
        }
        if old.paidByID != new.paidByID {
            changes.append(
                AuditChange(
                    "Paid by",
                    from: name(old.paidByID, in: trip),
                    to: name(new.paidByID, in: trip)
                )
            )
        }
        if old.paymentMethod != new.paymentMethod {
            changes.append(
                AuditChange("Method", from: old.paymentMethod?.label, to: new.paymentMethod?.label)
            )
        }
        if old.receiptURL != new.receiptURL {
            changes.append(
                AuditChange(
                    "Receipt",
                    from: old.receiptURL == nil ? nil : "attached",
                    to: new.receiptURL == nil ? nil : "attached"
                )
            )
        }

        guard !changes.isEmpty else { return }

        record(
            AuditEvent(
                tripID: trip.id,
                kind: Self.kind(for: old, to: new),
                subjectID: new.id,
                subject: new.title,
                summary: Self.summary(from: old, to: new, in: trip),
                changes: changes,
                amount: new.cost > 0 ? new.cost : nil,
                currencyCode: currency
            )
        )
    }

    /// Which of several simultaneous changes the entry is filed under.
    ///
    /// Ordered by what somebody scrolling the trail is looking for. A payment
    /// appearing outranks the price moving, the price moving outranks the
    /// split, and a retitle only wins when it's the only thing that happened.
    private static func kind(for old: ItineraryItem, to new: ItineraryItem) -> AuditEvent.Kind {
        if old.paidByID == nil, new.paidByID != nil { return .paymentRecorded }
        if old.paidByID != nil, new.paidByID == nil { return .paymentCleared }
        if old.paidByID != new.paidByID { return .paymentChanged }
        if old.cost != new.cost { return .amountChanged }
        if old.split != new.split || old.customShares != new.customShares { return .splitChanged }
        if old.participantIDs != new.participantIDs { return .participantsChanged }
        if old.receiptURL != new.receiptURL, new.receiptURL != nil { return .receiptAttached }
        if old.paymentMethod != new.paymentMethod { return .paymentChanged }
        if !Calendar.current.isDate(old.date, inSameDayAs: new.date) || old.time != new.time {
            return .scheduleChanged
        }
        return .expenseUpdated
    }

    private static func summary(from old: ItineraryItem, to new: ItineraryItem, in trip: Trip) -> String {
        let currency = trip.currencyCode

        if old.paidByID == nil, let payer = new.paidByID {
            let who = payer == Traveller.you.id ? "you" : (trip.traveller(payer)?.name ?? "someone")
            let method = new.paymentMethod.map { " by \($0.label.lowercased())" } ?? ""
            return "Recorded \(Money.format(new.cost, code: currency)) paid for \(new.title) by \(who)\(method)"
        }
        if old.paidByID != nil, new.paidByID == nil {
            return "Removed the payment record on \(new.title)"
        }
        if old.paidByID != new.paidByID {
            return "Changed who paid for \(new.title) to \(name(new.paidByID, in: trip) ?? "nobody")"
        }
        if old.cost != new.cost {
            let direction = new.cost > old.cost ? "up" : "down"
            return "Changed \(new.title) \(direction) from \(Money.format(old.cost, code: currency)) to \(Money.format(new.cost, code: currency))"
        }
        if old.split != new.split {
            return "Changed how \(new.title) is split — \(new.split.label.lowercased())"
        }
        if old.customShares != new.customShares {
            return "Changed the exact shares on \(new.title)"
        }
        if old.participantIDs != new.participantIDs {
            return "Changed who is on \(new.title)"
        }
        if !Calendar.current.isDate(old.date, inSameDayAs: new.date) || old.time != new.time {
            return "Rescheduled \(new.title)"
        }
        if old.receiptURL != new.receiptURL, new.receiptURL != nil {
            return "Attached a receipt to \(new.title)"
        }
        if old.title != new.title {
            return "Renamed \(old.title) to \(new.title)"
        }
        return "Edited \(new.title)"
    }

    /// A booking whose price fell out of a confirmed departure rather than out
    /// of anybody's typing. Filed separately so a trail reader can tell the
    /// two apart, which is the first thing they'll want to know.
    func repriced(_ item: ItineraryItem, from previous: Double, by leaver: String, in trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .repriced,
                subjectID: item.id,
                subject: item.title,
                summary: "\(item.title) repriced automatically after \(leaver) left",
                changes: [
                    AuditChange(
                        "Amount",
                        from: Money.format(previous, code: trip.currencyCode),
                        to: Money.format(item.cost, code: trip.currencyCode)
                    )
                ],
                amount: item.cost,
                currencyCode: trip.currencyCode
            )
        )
    }

    // MARK: - Disputes

    func disputeRaised(on item: ItineraryItem, reason: String?, in trip: Trip) {
        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .disputeRaised,
                subjectID: item.id,
                subject: item.title,
                summary: "Disputed the payment on \(item.title)",
                changes: [
                    AuditChange("Status", from: "Accepted", to: "Disputed"),
                    .set("Reason", trimmed.flatMap { $0.isEmpty ? nil : $0 } ?? "No reason given"),
                    .set("Paid by", name(item.paidByID, in: trip) ?? "nobody")
                ],
                amount: item.cost > 0 ? item.cost : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    func disputeResolved(on item: ItineraryItem, in trip: Trip) {
        var changes: [AuditChange] = [AuditChange("Status", from: "Disputed", to: "Resolved")]
        if let raisedBy = name(item.disputedByID, in: trip) {
            changes.append(.set("Raised by", raisedBy))
        }
        if let raisedAt = item.disputedAt {
            changes.append(
                .set("Open for", Self.span(from: raisedAt, to: item.disputeResolvedAt ?? Date()))
            )
        }

        record(
            AuditEvent(
                tripID: trip.id,
                kind: .disputeResolved,
                subjectID: item.id,
                subject: item.title,
                summary: "Resolved the dispute on \(item.title)",
                changes: changes,
                amount: item.cost > 0 ? item.cost : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    // MARK: - Settle-ups

    func settlementRequested(_ settlement: Settlement, in trip: Trip) {
        let to = name(settlement.toID, in: trip) ?? "someone"
        var changes: [AuditChange] = [
            .set("Amount", Money.format(settlement.amount, code: settlement.currencyCode)),
            .set("From", name(settlement.fromID, in: trip) ?? "someone"),
            .set("To", to),
            .set("Method", settlement.method.label)
        ]
        if !settlement.note.isEmpty { changes.append(.set("Note", settlement.note)) }
        if settlement.proofURL != nil { changes.append(.set("Proof", "attached")) }

        record(
            AuditEvent(
                tripID: trip.id,
                kind: .settlementRequested,
                subjectID: settlement.id,
                subject: "\(Money.format(settlement.amount, code: settlement.currencyCode)) to \(to)",
                summary: "Claimed a \(Money.format(settlement.amount, code: settlement.currencyCode)) \(settlement.method.label.lowercased()) payment to \(to), waiting on their confirmation",
                changes: changes,
                amount: settlement.amount,
                currencyCode: settlement.currencyCode
            )
        )
    }

    func settlementAnswered(_ settlement: Settlement, with status: Settlement.Status, in trip: Trip) {
        let from = name(settlement.fromID, in: trip) ?? "someone"
        let money = Money.format(settlement.amount, code: settlement.currencyCode)
        let confirmed = status == .confirmed

        record(
            AuditEvent(
                tripID: trip.id,
                kind: confirmed ? .settlementConfirmed : .settlementDeclined,
                subjectID: settlement.id,
                subject: "\(money) from \(from)",
                summary: confirmed
                    ? "Confirmed receiving \(money) from \(from) — that balance is closed"
                    : "Said the \(money) from \(from) never arrived",
                changes: [
                    AuditChange("Status", from: "Pending", to: confirmed ? "Confirmed" : "Declined"),
                    .set("Method", settlement.method.label),
                    .set("Claimed", DateFormatter.cached("d MMM yyyy, h:mm a").string(from: settlement.createdAt))
                ],
                amount: settlement.amount,
                currencyCode: settlement.currencyCode
            )
        )
    }

    func settlementWithdrawn(_ settlement: Settlement, in trip: Trip) {
        let to = name(settlement.toID, in: trip) ?? "someone"
        let money = Money.format(settlement.amount, code: settlement.currencyCode)

        record(
            AuditEvent(
                tripID: trip.id,
                kind: .settlementWithdrawn,
                subjectID: settlement.id,
                subject: "\(money) to \(to)",
                summary: "Withdrew the \(money) claim to \(to) before it was answered",
                changes: [AuditChange("Status", from: "Pending", to: "Withdrawn")],
                amount: settlement.amount,
                currencyCode: settlement.currencyCode
            )
        )
    }

    // MARK: - People

    func memberInvited(_ traveller: Traveller, to trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .memberInvited,
                subjectID: traveller.id,
                subject: traveller.name,
                summary: "Invited \(traveller.name) to the trip",
                changes: [
                    .set("Status", "Invited — bears no share until they accept"),
                    .set("Email", traveller.email ?? "not given")
                ],
                currencyCode: trip.currencyCode
            )
        )
    }

    func invitationCancelled(of traveller: Traveller, in trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .invitationCancelled,
                subjectID: traveller.id,
                subject: traveller.name,
                summary: "Withdrew \(traveller.name)'s invitation",
                changes: [AuditChange("Status", from: "Invited", to: "Not on the trip")],
                currencyCode: trip.currencyCode
            )
        )
    }

    func memberJoined(_ trip: Trip, travellerCount: Int) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .memberJoined,
                subjectID: Traveller.you.id,
                subject: Traveller.you.name,
                summary: "Joined the trip — every equally-split cost now divides \(travellerCount) ways",
                changes: [
                    AuditChange("Travellers", from: "\(max(0, travellerCount - 1))", to: "\(travellerCount)")
                ],
                currencyCode: trip.currencyCode
            )
        )
    }

    // MARK: - Departures

    func departureProposed(_ departure: TripDeparture, of traveller: Traveller, in trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .departureProposed,
                subjectID: departure.id,
                subject: traveller.name,
                summary: "Proposed that \(traveller.name) leaves on \(DateFormatter.cached("d MMM").string(from: departure.leftAt))",
                changes: departureChanges(departure, status: nil, in: trip),
                amount: departure.agreedBalance != 0 ? departure.agreedBalance : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    func departureAnswered(
        _ departure: TripDeparture,
        of traveller: Traveller,
        with status: TripDeparture.Status,
        in trip: Trip
    ) {
        let confirmed = status == .confirmed
        record(
            AuditEvent(
                tripID: trip.id,
                kind: confirmed ? .departureConfirmed : .departureDeclined,
                subjectID: departure.id,
                subject: traveller.name,
                summary: confirmed
                    ? "Confirmed \(traveller.name)'s exit — their side of the ledger is closed at \(Money.format(departure.agreedBalance, code: trip.currencyCode, signed: true))"
                    : "Declined \(traveller.name)'s exit — nothing about the ledger changed",
                changes: departureChanges(departure, status: status, in: trip),
                amount: confirmed ? departure.agreedBalance : nil,
                currencyCode: trip.currencyCode
            )
        )
    }

    func departureWithdrawn(_ departure: TripDeparture, of traveller: Traveller, in trip: Trip) {
        record(
            AuditEvent(
                tripID: trip.id,
                kind: .departureWithdrawn,
                subjectID: departure.id,
                subject: traveller.name,
                summary: "Withdrew \(traveller.name)'s exit proposal",
                changes: [AuditChange("Status", from: "Waiting to be confirmed", to: "Withdrawn")],
                currencyCode: trip.currencyCode
            )
        )
    }

    private func departureChanges(
        _ departure: TripDeparture,
        status: TripDeparture.Status?,
        in trip: Trip
    ) -> [AuditChange] {
        var changes: [AuditChange] = [
            .set("Last day", DateFormatter.cached("d MMM yyyy").string(from: departure.leftAt))
        ]
        if let status {
            changes.insert(AuditChange("Status", from: "Waiting to be confirmed", to: status.label), at: 0)
        }
        if departure.agreedBalance != 0 {
            changes.append(
                .set("Final balance", Money.format(departure.agreedBalance, code: trip.currencyCode, signed: true))
            )
        }
        let borne = departure.dispositions.values.filter(\.isBorne).count
        let dropped = departure.dispositions.count - borne
        if !departure.dispositions.isEmpty {
            changes.append(.set("Bookings", "\(borne) still charged, \(dropped) dropped"))
        }
        if !departure.note.isEmpty { changes.append(.set("Note", departure.note)) }
        return changes
    }

    // MARK: - Naming

    private func name(_ id: UUID?, in trip: Trip) -> String? {
        guard let id else { return nil }
        return trip.traveller(id)?.name
    }

    private static func name(_ id: UUID?, in trip: Trip) -> String? {
        guard let id else { return nil }
        return trip.traveller(id)?.name
    }

    private func names(_ ids: Set<UUID>, in trip: Trip) -> String {
        let resolved = ids.compactMap { trip.traveller($0)?.name }.sorted()
        return resolved.isEmpty ? "nobody" : resolved.joined(separator: ", ")
    }

    private func shareSummary(_ shares: [UUID: Double], in trip: Trip) -> String? {
        guard !shares.isEmpty else { return nil }
        return shares
            .compactMap { id, amount -> String? in
                guard let person = trip.traveller(id)?.name else { return nil }
                return "\(person) \(Money.format(amount, code: trip.currencyCode))"
            }
            .sorted()
            .joined(separator: ", ")
    }

    /// "3 days", "4 hours" — how long a dispute stayed open. Coarse on
    /// purpose: the exact stamps are on both entries for anyone who needs them.
    private static func span(from start: Date, to end: Date) -> String {
        let seconds = max(0, end.timeIntervalSince(start))
        if seconds < 3600 { return max(1, Int(seconds / 60)).pluralised("minute") }
        if seconds < 86_400 { return max(1, Int(seconds / 3600)).pluralised("hour") }
        return max(1, Int(seconds / 86_400)).pluralised("day")
    }
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var auditTrail = AuditTrail()
}
