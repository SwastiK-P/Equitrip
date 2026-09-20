//
//  SupabaseRows.swift
//  Equitrip
//

import SwiftUI
import Supabase

// MARK: - Rows

struct ProfileRow: Codable {
    let id: UUID
    var user_id: UUID?
    var display_name: String
    var avatar_asset: String
    /// A photograph the person chose. `avatar_asset` is the avatar behind it,
    /// and stays the fallback so everybody has a face either way.
    var avatar_url: String?
    /// The VPA this person pays into. Null until they set one in Settings —
    /// see `0011_profile_upi_id.sql`.
    var upi_id: String?

    init(
        id: UUID,
        user_id: UUID?,
        display_name: String,
        avatar_asset: String,
        avatar_url: String? = nil,
        upi_id: String? = nil
    ) {
        self.id = id
        self.user_id = user_id
        self.display_name = display_name
        self.avatar_asset = avatar_asset
        self.avatar_url = avatar_url
        self.upi_id = upi_id
    }

    /// The signed-in user keeps the app-wide "you" identity so every
    /// `isYou` check and avatar stays consistent with what's on device.
    func asTraveller(currentProfile: UUID) -> Traveller {
        id == currentProfile
            ? Traveller(
                id: id,
                name: CurrentUser.traveller.name,
                asset: CurrentUser.traveller.asset,
                avatarURL: CurrentUser.traveller.avatarURL,
                upiVPA: CurrentUser.traveller.upiVPA
            )
            : Traveller(
                id: id,
                name: display_name,
                asset: Traveller.artwork(for: avatar_asset),
                avatarURL: avatar_url.flatMap(URL.init(string:)),
                upiVPA: upi_id
            )
    }
}

struct MembershipRow: Codable { let trip_id: UUID }

/// Just a profile's id — for checking which rows already exist.
struct ProfileIDRow: Decodable { let id: UUID }

/// One person on a trip, seen from outside it, as `trip_people_by_code`
/// returns them: a name and a face for the join preview, and no UPI ID.
struct TripPreviewPersonRow: Decodable {
    let profile_id: UUID
    let role: String
    let display_name: String
    let avatar_asset: String
    let avatar_url: String?

    var profile: ProfileRow {
        ProfileRow(
            id: profile_id,
            user_id: nil,
            display_name: display_name,
            avatar_asset: avatar_asset,
            avatar_url: avatar_url
        )
    }
}

/// What `join_trip` answers: the trip, and whether this call put you on it.
struct JoinTripRow: Decodable {
    let trip: UUID
    let joined: Bool
}

/// What `trip_preview` answers with: the two numbers the join screen states,
/// and deliberately nothing that would amount to handing over the itinerary.
struct TripPreviewRow: Decodable {
    let trip_id: UUID
    let booking_count: Int
    let total_cost: Double
}

struct NotificationRow: Codable {
    var id: UUID
    var profile_id: UUID
    var trip_id: UUID?
    var settlement_id: UUID?
    var item_id: UUID?
    var kind: String
    var title: String
    var body: String
    var is_read: Bool
    var created_at: Date

    init(notification: AppNotification, profileID: UUID) {
        id = notification.id
        profile_id = profileID
        trip_id = notification.tripID
        settlement_id = notification.settlementID
        item_id = notification.itemID
        kind = notification.kind.rawValue
        title = notification.title
        body = notification.body
        is_read = !notification.isUnread
        created_at = notification.date
    }

    /// An unrecognised `kind` reads as `.booking` rather than being dropped —
    /// a notification whose glyph we can't pick is still worth showing.
    var asNotification: AppNotification {
        AppNotification(
            id: id,
            kind: ActivityEvent.Kind(rawValue: kind) ?? .booking,
            title: title,
            body: body,
            date: created_at,
            isUnread: !is_read,
            tripID: trip_id,
            itemID: item_id,
            settlementID: settlement_id
        )
    }
}

// MARK: - Audit row

/// The `trip_audit_events` row. Every field is a snapshot — see the migration
/// for why none of them are joins.
struct AuditEventRow: Codable {
    var id: UUID
    var trip_id: UUID
    var kind: String
    var actor_profile_id: UUID?
    var actor_name: String
    var subject_id: UUID?
    var subject: String
    var summary: String
    var changes: [AuditChange]
    var amount: Double?
    var currency_code: String
    var created_at: Date

    /// The actor is taken from the resolved profile rather than from the
    /// event, because the insert policy compares it against
    /// `current_profile_id()` — an id assembled on device would be a write
    /// that silently fails RLS.
    init(event: AuditEvent, actorProfileID: UUID) {
        id = event.id
        trip_id = event.tripID
        kind = event.kind.rawValue
        actor_profile_id = actorProfileID
        actor_name = event.actorName
        subject_id = event.subjectID
        subject = event.subject
        summary = event.summary
        changes = event.changes
        amount = event.amount
        currency_code = event.currencyCode
        created_at = event.at
    }

    var asAuditEvent: AuditEvent {
        AuditEvent(
            id: id,
            tripID: trip_id,
            kind: AuditEvent.Kind.decode(kind),
            actorID: actor_profile_id,
            actorName: actor_name,
            subjectID: subject_id,
            subject: subject,
            summary: summary,
            changes: changes,
            amount: amount,
            currencyCode: currency_code,
            at: created_at
        )
    }
}

// MARK: - Settlement row

struct SettlementRow: Codable {
    var id: UUID
    var trip_id: UUID
    var from_profile: UUID
    var to_profile: UUID
    var amount: Double
    var currency_code: String
    var method: String
    var proof_url: String?
    var note: String
    var status: String
    var created_by: UUID?
    var created_at: Date
    var responded_by: UUID?
    var responded_at: Date?

    init(settlement: Settlement) {
        id = settlement.id
        trip_id = settlement.tripID
        from_profile = settlement.fromID
        to_profile = settlement.toID
        amount = settlement.amount
        currency_code = settlement.currencyCode
        method = settlement.method.rawValue
        proof_url = settlement.proofURL?.absoluteString
        note = settlement.note
        status = settlement.status.rawValue
        created_by = settlement.createdByID
        created_at = settlement.createdAt
        responded_by = settlement.respondedByID
        responded_at = settlement.respondedAt
    }

    var asSettlement: Settlement {
        Settlement(
            id: id,
            tripID: trip_id,
            fromID: from_profile,
            toID: to_profile,
            amount: amount,
            currencyCode: currency_code,
            method: PaymentMethod(rawValue: method) ?? .cash,
            proofURL: proof_url.flatMap(URL.init(string:)),
            note: note,
            status: Settlement.Status(rawValue: status) ?? .pending,
            createdByID: created_by ?? from_profile,
            createdAt: created_at,
            respondedByID: responded_by,
            respondedAt: responded_at
        )
    }
}

struct TripMemberRow: Codable {
    var trip_id: UUID
    var profile_id: UUID
    var role: String
    /// "invited" or "active". Optional because it's decoded from rows written
    /// without it — a new trip's starting roster takes the column's `active`
    /// default. Only `invite` sets it on a write.
    var status: String?
    var invited_by: UUID?
    var invited_at: Date?

    var isInvited: Bool { status == "invited" }
}

/// A new trip's starting roster, as `createTrip` writes it: identity and role
/// only, so `status` takes its `active` default.
///
/// A separate type rather than an optional field on `TripMemberRow`, because
/// encoding a nil would send an explicit null and violate the not-null
/// constraint; omitting the property is the only way to get the default.
struct TripMemberWrite: Codable {
    var trip_id: UUID
    var profile_id: UUID
    var role: String
}

// MARK: - Departure row

/// One person's exit from one trip.
///
/// The per-booking decisions ride along as JSON rather than as a child table.
/// They're a closed snapshot — written once when the exit is proposed, read
/// back whole, never queried a row at a time — so a join table would buy
/// nothing but a second round trip and a second thing to keep in step.
struct DepartureRow: Codable {
    var id: UUID
    var trip_id: UUID
    var profile_id: UUID
    var left_at: String
    var status: String
    var note: String
    /// Booking id → `TripDeparture.Disposition`.
    var dispositions: [String: String]
    /// Booking id → what it worked out to when both sides agreed.
    var amounts: [String: Double]
    var agreed_balance: Double
    var proposed_by: UUID?
    var proposed_at: Date
    var responded_by: UUID?
    var responded_at: Date?

    init(_ departure: TripDeparture) {
        id = departure.id
        trip_id = departure.tripID
        profile_id = departure.travellerID
        left_at = SupabaseFormat.day.string(from: departure.leftAt)
        status = departure.status.rawValue
        note = departure.note
        dispositions = departure.dispositions.reduce(into: [:]) { $0[$1.key.uuidString] = $1.value.rawValue }
        amounts = departure.agreedAmounts.reduce(into: [:]) { $0[$1.key.uuidString] = $1.value }
        agreed_balance = departure.agreedBalance
        proposed_by = departure.proposedByID
        proposed_at = departure.proposedAt
        responded_by = departure.respondedByID
        responded_at = departure.respondedAt
    }

    var asDeparture: TripDeparture {
        TripDeparture(
            id: id,
            tripID: trip_id,
            travellerID: profile_id,
            leftAt: SupabaseFormat.day.date(from: left_at) ?? proposed_at,
            // An unknown status reads as pending rather than confirmed. A
            // build that doesn't recognise a value it's been handed must not
            // be the one that decides somebody's ledger is closed.
            status: TripDeparture.Status(rawValue: status) ?? .pending,
            dispositions: dispositions.reduce(into: [:]) { store, entry in
                guard let key = UUID(uuidString: entry.key),
                      let value = TripDeparture.Disposition(rawValue: entry.value) else { return }
                store[key] = value
            },
            agreedAmounts: amounts.reduce(into: [:]) { store, entry in
                if let key = UUID(uuidString: entry.key) { store[key] = entry.value }
            },
            agreedBalance: agreed_balance,
            note: note,
            proposedByID: proposed_by,
            proposedAt: proposed_at,
            respondedByID: responded_by,
            respondedAt: responded_at
        )
    }
}

struct ParticipantRow: Codable {
    var item_id: UUID
    var profile_id: UUID
    /// What this person owes on this booking, when the split is `.custom`.
    ///
    /// Null for every other mode, and that's the distinction that matters: a
    /// null means "work it out from the cost", a zero means "somebody decided
    /// this person owes nothing". Storing it here rather than as JSON on the
    /// booking keeps it referentially tied to the participant row it belongs
    /// to, so removing someone from a booking takes their figure with them.
    var amount: Double?

    init(item: ItineraryItem, profileID: UUID) {
        item_id = item.id
        profile_id = profileID
        amount = item.split.isCustom ? (item.customShares[profileID] ?? 0) : nil
    }
}

struct TripRow: Codable {
    var id: UUID
    var title: String
    var destination: String
    var start_date: String
    var end_date: String
    var currency_code: String
    var symbol: String
    var tint_hex: String
    var cover_url: String?
    /// Optional so a row read before migration 0019 still decodes.
    var title_style: String?
    var invite_code: String
    var created_by: UUID?

    init(trip: Trip, createdBy: UUID) {
        id = trip.id
        title = trip.title
        destination = trip.destination
        start_date = SupabaseFormat.day.string(from: trip.startDate)
        end_date = SupabaseFormat.day.string(from: trip.endDate)
        currency_code = trip.currencyCode
        symbol = trip.symbol
        tint_hex = "4B45C6"
        cover_url = trip.cover?.url.absoluteString
        title_style = trip.titleStyle.rawValue
        invite_code = Trip.normaliseCode(trip.inviteCode)
        created_by = createdBy
    }

    func asTrip(
        travellers: [Traveller],
        organiserIDs: Set<UUID>,
        invitedIDs: Set<UUID> = [],
        items: [ItineraryItem],
        settlements: [Settlement] = [],
        departures: [TripDeparture] = []
    ) -> Trip {
        Trip(
            id: id,
            title: title,
            destination: destination,
            startDate: SupabaseFormat.day.date(from: start_date) ?? Date(),
            endDate: SupabaseFormat.day.date(from: end_date) ?? Date(),
            currencyCode: currency_code,
            symbol: symbol,
            tint: Palette.tint(forHex: tint_hex),
            travellers: travellers,
            items: items,
            settlements: settlements,
            departures: departures,
            invitedIDs: invitedIDs,
            organiserIDs: organiserIDs,
            cover: cover_url.flatMap(URL.init(string:)).map {
                TripPhoto(url: $0, thumbURL: $0, photographer: "", photographerURL: nil, sourceName: "")
            },
            titleStyle: TripTitleStyle(stored: title_style)
        )
    }
}

struct ItemRow: Codable {
    var id: UUID
    var trip_id: UUID
    var title: String
    var vendor: String
    var kind: String
    var day: String
    var start_time: Date?
    var cost: Double
    var split: String
    var photo_query: String?
    var cover_url: String?
    var suggested_symbol: String?
    /// The `flight` jsonb column. A whole sub-record that only applies to one
    /// kind of booking, so it rides as JSON rather than eleven mostly-null
    /// columns — see the note in `0001_init.sql`.
    var flight: FlightDetails?
    var paid_by: UUID?
    var payment_method: String?
    var receipt_url: String?
    var created_by: UUID?
    var is_disputed: Bool?
    var disputed_by: UUID?
    var disputed_at: Date?
    var dispute_reason: String?
    var dispute_resolved_at: Date?
    var dispute_resolved_by: UUID?

    init(item: ItineraryItem, tripID: UUID) {
        id = item.id
        trip_id = tripID
        title = item.title
        vendor = item.vendor
        kind = item.kind.rawValue
        day = SupabaseFormat.day.string(from: item.day)
        start_time = item.time
        cost = item.cost
        split = item.split.rawValue
        photo_query = item.photoQuery
        cover_url = item.cover?.url.absoluteString
        suggested_symbol = item.suggestedSymbol
        flight = item.flight
        paid_by = item.paidByID
        payment_method = item.paymentMethod?.rawValue
        receipt_url = item.receiptURL?.absoluteString
        created_by = item.createdByID
        is_disputed = item.isDisputed
        disputed_by = item.disputedByID
        disputed_at = item.disputedAt
        dispute_reason = item.disputeReason
        dispute_resolved_at = item.disputeResolvedAt
        dispute_resolved_by = item.disputeResolvedByID
    }

    func asItineraryItem(participantIDs: Set<UUID>, customShares: [UUID: Double] = [:]) -> ItineraryItem {
        ItineraryItem(
            id: id,
            title: title,
            vendor: vendor,
            kind: ItineraryKind(rawValue: kind) ?? .other,
            date: SupabaseFormat.day.date(from: day) ?? Date(),
            time: start_time,
            cost: cost,
            split: SplitMode.decode(split),
            participantIDs: participantIDs,
            customShares: customShares,
            photoQuery: photo_query,
            cover: cover_url.flatMap(URL.init(string:)).map {
                TripPhoto(url: $0, thumbURL: $0, photographer: "", photographerURL: nil, sourceName: "")
            },
            suggestedSymbol: suggested_symbol,
            flight: flight,
            paidByID: paid_by,
            paymentMethod: payment_method.flatMap(PaymentMethod.init(rawValue:)),
            receiptURL: receipt_url.flatMap(URL.init(string:)),
            createdByID: created_by,
            isDisputed: is_disputed ?? false,
            disputedByID: disputed_by,
            disputedAt: disputed_at,
            disputeReason: dispute_reason,
            disputeResolvedAt: dispute_resolved_at,
            disputeResolvedByID: dispute_resolved_by
        )
    }
}

enum SupabaseFormat {
    /// Postgres `date` columns are plain calendar days with no zone; parsing
    /// them in the local zone is what keeps a booking on the day it was
    /// entered rather than sliding either side of midnight.
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}
