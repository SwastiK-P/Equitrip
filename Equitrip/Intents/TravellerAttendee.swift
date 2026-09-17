//
//  TravellerAttendee.swift
//  Equitrip
//

import AppIntents
import Foundation

/// A person on a booking, in the calendar schema's terms.
///
/// Transient: an attendee only exists as part of a booking, and is never
/// looked up on its own — the way CometCal's attendees exist only through
/// their events. The traveller's server id travels as the person's
/// application-defined identifier, so a round trip through Siri still says
/// exactly who.
@AppEntity(schema: .calendar.attendee)
struct TravellerAttendee: nonisolated TransientAppEntity {

    var person: IntentPerson
    var status: AttendanceStatus?
    var isAttendanceOptional: Bool
    var type: AttendeeKind?

    nonisolated init() {
        person = IntentPerson(identifier: .unknown, name: .unknown, handle: nil)
        status = nil
        isAttendanceOptional = false
        type = nil
    }

    @MainActor
    init(_ traveller: Traveller, invited: Bool) {
        person = IntentPerson.traveller(traveller)
        // Somebody asked and not yet answered is on the booking in name only
        // — the same rule `Trip.bearers(of:)` applies to the money.
        status = invited ? .tentative : .accepted
        isAttendanceOptional = false
        type = .traveller
    }

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(person.displayName)")
    }
}

@AppEnum(schema: .calendar.attendeeStatus)
enum AttendanceStatus: String {
    case accepted
    case declined
    case tentative

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .accepted: "On it",
        .declined: "Not on it",
        .tentative: "Invited"
    ]
}

/// The schema leaves the kinds of attendee to the app. A trip has one.
@AppEnum(schema: .calendar.attendeeType)
enum AttendeeKind: String {
    case traveller

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .traveller: "Traveller"
    ]
}

extension IntentPerson {
    /// A traveller as a person the system can hold. The email is the handle
    /// when there is one, so Siri can line a traveller up with a contact.
    @MainActor
    static func traveller(_ traveller: Traveller) -> IntentPerson {
        IntentPerson(
            identifier: .applicationDefined(traveller.id.uuidString),
            name: .displayName(traveller.name),
            handle: traveller.email.map { IntentPerson.Handle(emailAddress: $0) },
            isMe: traveller.id == Traveller.you.id
        )
    }

    /// The name to say or show for this person, whatever form it came in.
    nonisolated var displayName: String {
        switch name {
        case .displayName(let name): return name
        case .components(let parts): return parts.formatted()
        default:
            if case .emailAddress(let email)? = handle?.value { return email }
            return "Someone"
        }
    }

    /// The traveller id this person was made from, when it came from here.
    nonisolated var travellerID: UUID? {
        guard case .applicationDefined(let raw) = identifier else { return nil }
        return UUID(uuidString: raw)
    }
}
