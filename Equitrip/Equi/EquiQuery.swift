//
//  EquiQuery.swift
//  Equitrip
//

import Foundation

/// What a question to Equi is about — topic, trip, category, person, day —
/// worked out before a word of the answer is written.
///
/// The first Equi handed the on-device model four whole trips and asked it to
/// answer and pick a card in one pass. It mixed trips up, often couldn't see
/// the one being asked about (the cap kept the four latest *start dates*, so
/// future trips crowded out past ones), and drew the same card however the
/// question was put. Now the question is read into one of these first
/// (`EquiQueryReader`), Swift answers it (`EquiFacts`), and the model only
/// has to understand and phrase.
struct EquiQuery: Equatable {

    enum Topic: String, Equatable {
        /// A trip as a whole: when, how it's going, a recap.
        case overview
        /// What happens next, today, tomorrow, or when one thing happens.
        case schedule
        /// What's booked of one kind: where you sleep, which flights.
        case bookings
        /// What things cost and where the money went.
        case spending
        /// Who owes whom.
        case balance
        /// Who is on the trip, and one person's part in it.
        case people
        /// Several trips at once: listing, counting, comparing.
        case trips
        /// What's missing from the plan.
        case gaps
        /// Packing, weather, sights — general travel knowledge.
        case advice
        /// Greetings, thanks, anything that isn't about a trip.
        case chat
    }

    enum Day: Equatable {
        case any, today, tomorrow
    }

    /// Which trips a question reaches for, before it is pinned to real ones.
    /// Kept on the query so an answer can say "you haven't finished a trip
    /// yet" rather than quietly describing a different one.
    enum Scope: Equatable {
        case named, current, next, previous, all, allPast, allUpcoming
    }

    var topic: Topic
    var scope: Scope
    /// The trips the answer is about, most relevant first. One for most
    /// topics; several for `.trips`, or a balance asked across every trip.
    /// Empty when the scope has nothing in it — no past trip to recap.
    var tripIDs: [UUID]
    var category: ItineraryKind?
    var personID: UUID?
    var day: Day
    /// "Which trip cost the most?" — trips ranked by what they cost rather
    /// than listed by when they are.
    var byCost = false
    /// "Am I over budget?" — the app records no budget, and the answer has
    /// to say so before it gives the total.
    var asksBudget = false

    var tripID: UUID? { tripIDs.first }
}
