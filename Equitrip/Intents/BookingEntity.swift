//
//  BookingEntity.swift
//  Equitrip
//

import AppIntents
import CoreSpotlight
import Foundation
import GeoToolbox

/// A booking or expense, as Siri, Spotlight, Shortcuts and Visual Intelligence
/// know it — an event on its trip's calendar. See `TripEntity` for why the
/// calendar schema.
///
/// Carries its money as *words* — "₹12,000, paid by Ed, your share ₹3,000" in
/// the note — and never as fields a system action could write back. The
/// calendar schema has nowhere to put a cost, and that's the right shape for
/// this app anyway: money on a booking is only ever set from the editor, where
/// the split and the payer are on screen beside it.
@AppEntity(schema: .calendar.event)
struct BookingEntity: nonisolated Identifiable, nonisolated IndexedEntity, nonisolated OwnershipProvidingEntity {

    static let defaultQuery = BookingEntityQuery()

    let id: UUID

    var calendar: TripEntity
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var recurrence: Calendar.RecurrenceRule?
    var note: AttributedString?
    var travelTime: Duration?
    var location: BookingLocation?
    var virtualLocation: URL?
    var status: BookingStatus?
    var alarms: [BookingAlarm]
    var organizers: [IntentPerson]
    var attendees: [TravellerAttendee]

    // Beyond the schema, for Shortcuts and the Spotlight attribute set.
    var kind: String
    var vendor: String
    var flightNumber: String?

    static let viewActivityType = "com.swastik.Equitrip.viewBooking"

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(kind) · \(calendar.title) · \(Self.when(startDate, allDay: isAllDay))",
            image: .init(systemName: symbol)
        )
    }

    nonisolated var ownership: EntityOwnership {
        calendar.ownership
    }

    nonisolated var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.startDate = startDate
        set.endDate = endDate
        set.allDay = NSNumber(value: isAllDay)
        set.namedLocation = vendor.isEmpty ? calendar.destination : vendor
        set.contentDescription = note.map { String($0.characters) }
        set.keywords = [kind, calendar.title, calendar.destination, vendor, flightNumber ?? ""].filter { !$0.isEmpty }
        return set
    }

    /// Kept off the schema's fields, which have no slot for a glyph.
    private var symbol: String

    @MainActor
    init(_ item: ItineraryItem, in trip: Trip) {
        // The fields beyond the schema first. The macro turns the schema's own
        // fields into wrapped properties, and assigning one of those reads
        // `self` — which has to be whole by then.
        kind = item.kind.label
        vendor = item.vendor
        flightNumber = item.flight?.number
        symbol = item.symbol

        id = item.id
        calendar = TripEntity(trip)
        title = item.title
        startDate = TripMatcher.start(of: item)
        isAllDay = item.time == nil
        endDate = Self.end(of: item, from: startDate)
        recurrence = nil
        note = AttributedString(Self.summary(of: item, in: trip))
        travelTime = nil
        location = item.vendorName.map(BookingLocation.address)
        virtualLocation = nil
        status = Self.status(of: item)
        alarms = []
        organizers = item.createdByID.flatMap(trip.traveller).map { [IntentPerson.traveller($0)] } ?? []
        attendees = trip.participants(of: item).map { TravellerAttendee($0, invited: trip.invitedIDs.contains($0.id)) }
    }

    // MARK: - Derived fields

    /// The booking's end, which the app doesn't store. A flight lands when its
    /// schedule says; anything else runs for as long as that kind of thing
    /// usually does, so "what's on at four" doesn't miss a three o'clock
    /// dinner — and a day-long stay covers the day.
    @MainActor
    private static func end(of item: ItineraryItem, from start: Date) -> Date {
        if let arrival = item.flight?.scheduledArrival, arrival > start { return arrival }
        guard item.time != nil else {
            return Calendar.current.date(byAdding: .day, value: 1, to: item.day) ?? start
        }
        let minutes: Int = switch item.kind {
        case .flight, .train: 120
        case .drive: 60
        case .stay: 24 * 60
        case .activity: 120
        case .meal: 90
        case .other: 60
        }
        return start.addingTimeInterval(TimeInterval(minutes * 60))
    }

    /// A disputed payment is a booking whose record is in question; a flight
    /// the airline cancelled is cancelled whatever the ledger says.
    @MainActor
    private static func status(of item: ItineraryItem) -> BookingStatus {
        if item.flight?.status == .cancelled { return .cancelled }
        return item.isDisputed ? .tentative : .confirmed
    }

    /// The money and the people, in a sentence Siri can read out and Spotlight
    /// can search — every figure straight off the ledger.
    @MainActor
    private static func summary(of item: ItineraryItem, in trip: Trip) -> String {
        var parts = [item.kind.label]
        if let vendor = item.vendorName { parts.append("at \(vendor)") }
        if let flight = item.flight {
            let route = [flight.departureCity ?? flight.departureAirport, flight.arrivalCity ?? flight.arrivalAirport]
                .compactMap { $0 }
                .joined(separator: " to ")
            parts.append([flight.number, route].filter { !$0.isEmpty }.joined(separator: ", "))
        }
        if item.cost > 0 {
            parts.append(Money.format(item.cost, code: trip.currencyCode))
            if let payer = item.paidByID.flatMap(trip.traveller) {
                parts.append("paid by \(payer.id == Traveller.you.id ? "you" : payer.name)")
            } else {
                parts.append("not paid yet")
            }
            let share = trip.share(of: item, for: Traveller.you.id)
            if share > 0 { parts.append("your share \(Money.format(share, code: trip.currencyCode))") }
        }
        let people = trip.participants(of: item).map(\.name)
        if !people.isEmpty { parts.append("with \(people.joined(separator: ", "))") }
        return parts.joined(separator: " · ")
    }

    nonisolated private static func when(_ date: Date, allDay: Bool) -> String {
        allDay
            ? date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
            : date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }
}

/// Looks bookings up across every trip in the signed-in account.
nonisolated struct BookingEntityQuery: EntityStringQuery, IndexedEntityQuery {

    func entities(for identifiers: [BookingEntity.ID]) async throws -> [BookingEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            let wanted = Set(identifiers)
            return store.trips.flatMap { trip in
                trip.items.filter { wanted.contains($0.id) }.map { BookingEntity($0, in: trip) }
            }
        }
    }

    func entities(matching string: String) async throws -> [BookingEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            TripMatcher.bookings(matching: string, in: store.trips)
                .prefix(20)
                .map { BookingEntity($0.item, in: $0.trip) }
        }
    }

    /// What's coming up soonest on the trips still ahead — the bookings a
    /// person is likeliest to be asking about.
    func suggestedEntities() async throws -> [BookingEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            let now = Date().addingTimeInterval(-3 * 3600)
            return store.trips
                .filter { $0.phase != .past }
                .flatMap { trip in trip.items.map { (trip, $0) } }
                .filter { TripMatcher.start(of: $0.1) >= now }
                .sorted { TripMatcher.start(of: $0.1) < TripMatcher.start(of: $1.1) }
                .prefix(15)
                .map { BookingEntity($0.1, in: $0.0) }
        }
    }

    func reindexEntities(for identifiers: [BookingEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndex.reindex()
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndex.reindex()
    }
}

// MARK: - Schema value types

@AppEnum(schema: .calendar.eventStatus)
enum BookingStatus: String {
    case confirmed
    case tentative
    case cancelled

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .confirmed: "Confirmed",
        .tentative: "Disputed",
        .cancelled: "Cancelled"
    ]
}

/// Bookings don't repeat, so every span means the one booking — but the
/// schema asks, and Siri may too.
@AppEnum(schema: .calendar.eventSpan)
enum BookingSpan: String {
    case this
    case future
    case all

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .this: "This Booking",
        .future: "Future Bookings",
        .all: "All Bookings"
    ]
}

@UnionValue
enum BookingLocation {
    case place(PlaceDescriptor)
    case address(String)
}

@UnionValue
enum BookingAlarm {
    case duration(Duration)
    case date(Date)
}
