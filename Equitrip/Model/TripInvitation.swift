//
//  TripInvitation.swift
//  Equitrip
//

import SwiftUI

/// A trip somebody has been asked to join, before they've answered.
///
/// Deliberately a `Trip` rather than a new type. What the person answering
/// wants to see is the trip — where, when, how much is booked, who else is
/// coming — and every one of those already renders from a `Trip`. The only
/// difference is what's *missing* from it: the itinerary, the chat and the
/// ledger are hidden by row-level security until they accept, which is why
/// `previewBookingCount` and `previewCost` exist and why they're used here
/// instead of counting `items`.
struct TripInvitation: Identifiable {
    /// The trip as much of it as an invitee is allowed to see.
    let trip: Trip
    /// Who asked, when the server told us.
    let invitedByID: UUID?
    let invitedAt: Date?

    var id: UUID { trip.id }

    var inviter: Traveller? {
        guard let invitedByID else { return nil }
        return trip.traveller(invitedByID)
    }

    /// "Priya invited you" — falls back to the organiser, then to nobody,
    /// because an invitation with no name attached still has to say something.
    var invitedByName: String? {
        inviter?.name ?? trip.organisers.first(where: { $0.id != Traveller.you.id })?.name
    }

    /// Everyone already on it — the invitee themselves excluded, since "and
    /// you" is not news to the person reading.
    var others: [Traveller] {
        trip.travellers.filter { $0.id != Traveller.you.id }
    }

    var when: String {
        let year = Calendar.current.component(.year, from: trip.startDate)
        let thisYear = Calendar.current.component(.year, from: Date())
        let suffix = year == thisYear ? "" : " \(year)"
        return trip.dateRange + suffix
    }
}

// MARK: - Trip integration

extension Trip {

    /// People who've been asked and haven't answered.
    var invitedTravellers: [Traveller] {
        travellers.filter { invitedIDs.contains($0.id) }
    }

    func isInvited(_ travellerID: UUID) -> Bool { invitedIDs.contains(travellerID) }

    /// You've been asked to this trip but haven't said yes.
    ///
    /// True only on the preview a `TripInvitation` carries — an accepted trip
    /// has already had the id taken out of `invitedIDs` by the time it reaches
    /// the app.
    var youAreInvited: Bool { invitedIDs.contains(Traveller.you.id) }

    /// Whether somebody counts for the ledger at all.
    ///
    /// The single question every "is this person on the trip" check should be
    /// asking. An invitee hasn't joined; somebody who left has stopped
    /// counting for anything after their exit. Both are travellers on the
    /// roster and neither is a live participant.
    func isOnTheTrip(_ travellerID: UUID) -> Bool {
        !invitedIDs.contains(travellerID) && !hasLeft(travellerID)
    }

    /// What to say under someone's name in the people sheet, if anything.
    var pendingInviteCount: Int { invitedIDs.count }
}
