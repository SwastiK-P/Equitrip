//
//  BookingChangeReader.swift
//  Equitrip
//

import Foundation
import FoundationModels

// MARK: - Schema

/// What the on-device model is asked about a booking email.
///
/// Every field is a `String` copied from the email, for the reason
/// `MailReading.amount` is: a copied string can be found again in the text,
/// and a computed one can't. The model is never asked *which* booking — that
/// is `BookingMatcher`'s job, on evidence a person can check — only what the
/// email says happened, which is the part rules read worst ("your 7:05 flight
/// will now leave at 9:40" has no "old" or "new" in it at all).
@Generable(description: "What an email from an airline, railway, hotel or tour operator says happened to one booking")
private struct ChangeReading {

    @Guide(description: """
        cancelled when the email says the booking has been cancelled or called off. \
        changed when its date, time or price has been changed, moved, rescheduled or delayed. \
        none for confirmations, reminders, check-in notices, receipts, refunds for an \
        earlier cancellation, policies about what would happen if, and advertisements.
        """)
    var outcome: ChangeOutcome

    @Guide(description: "The booking's new date, copied exactly as written. Empty when the date did not change or is not stated.")
    var newDate: String

    @Guide(description: "The booking's new departure, start or check-in time, copied exactly as written. Empty when not stated.")
    var newTime: String

    @Guide(description: "The time the booking used to be at, copied exactly as written. Empty when not stated.")
    var previousTime: String

    @Guide(description: "The new total price, digits exactly as written, no currency symbol. Empty when the email gives none.")
    var newTotal: String

    @Guide(description: "The amount being refunded, digits exactly as written, no currency symbol. Empty when the email gives none.")
    var refund: String
}

@Generable
private enum ChangeOutcome {
    case cancelled
    case changed
    case none
}

// MARK: - Reader

/// Reads one email, on this device, and decides whether it changes a booking
/// on one of your trips — and which.
///
/// Four passes. `BookingMailGate` drops anything that doesn't say a booking
/// was cancelled or changed. `BookingMailFacts` reads what it can by rule:
/// flight numbers, old and new times, refunds. The model reads the same
/// email for what rules miss, and everything it returns has to be found in
/// the text again before it counts. Then `BookingMatcher` decides which
/// booking, on which trip — or says it can't.
///
/// Rules win where they found something. They only ever return text they
/// found next to a label that says what it is; the model fills gaps. Without
/// Apple Intelligence (the Simulator, older phones) the rules are the whole
/// reader, and every case in the test fixtures is answered by them alone.
@MainActor
enum BookingChangeReader {

    enum Outcome {
        case found(BookingChange)
        /// Not a change, or not one of yours — with the reason, which the
        /// paste flow shows and the sync drops.
        case skipped(String)
    }

    private static let instructions = """
        You read one email from a travel company and report only what it says \
        happened to the booking.

        Rules:
        - Copy. Never calculate, never convert, never tidy. Every field you fill \
        must appear in the email in those characters.
        - An empty field is a correct answer when the email does not say.
        - A policy is not an event. "If your flight is cancelled you will be \
        refunded" and "free cancellation until 25 Sep" describe what could \
        happen; they are not a cancellation.
        - A new booking confirmation, a check-in reminder or a receipt is none.
        """

    static func read(
        _ message: MailMessage,
        trips: [Trip],
        source: BookingChange.Source
    ) async -> Outcome {
        let verdict = BookingMailGate.check(message)
        if case .rejected(let reason) = verdict { return .skipped(reason) }

        let text = message.readableText
        var facts = BookingMailFacts.read(text, isCancellation: verdict == .cancellation, referenceDate: message.receivedAt)

        if ExpenseMailReader.isAvailable {
            do {
                let reading = try await LanguageModelSession(instructions: instructions)
                    .respond(to: "Read this email.\n\n\(text)", generating: ChangeReading.self)
                    .content
                if let reason = merge(reading, into: &facts, text: text, referenceDate: message.receivedAt) {
                    return .skipped(reason)
                }
            } catch {
                // The rules have already read it; carry on with what they found.
            }
        }

        let bookings = trips.flatMap { trip in trip.items.map { booking(for: $0, in: trip) } }
        let people = trips.map { BookingMatcher.TripPeople(tripID: $0.id, names: $0.travellers.map(\.name)) }

        let outcome = BookingMatcher.match(text: text, facts: facts, bookings: bookings, trips: people)

        var change = BookingChange(
            id: message.id,
            tripID: nil,
            itemID: nil,
            alternatives: [],
            reasons: [],
            kind: facts.isCancellation ? .cancelled : .changed,
            newDay: nil,
            newMinute: nil,
            newCost: nil,
            refund: facts.refund,
            cancellationCharge: facts.cancellationCharge,
            currencyCode: facts.currencyCode,
            reference: facts.reference,
            sender: message.fromName,
            subject: message.subject,
            receivedAt: message.receivedAt,
            source: source,
            confidence: .likely,
            status: .waiting,
            detectedAt: Date(),
            before: nil,
            seen: true
        )

        if !facts.isCancellation {
            // Labelled values first; an unlabelled check-in or departure only
            // when nothing on the email was marked as new.
            change.newDay = facts.newDay ?? (facts.hasNewSchedule ? nil : facts.statedDay)
            change.newMinute = facts.newMinute ?? (facts.hasNewSchedule ? nil : facts.statedMinute)
            // A bare "Total fare" on a reschedule notice is usually the fare as
            // booked, often per passenger — it only counts as the booking's new
            // cost on a mail that isn't moving the schedule.
            change.newCost = facts.revisedTotal ?? (facts.hasNewSchedule ? nil : facts.statedTotal)
        }

        switch outcome {
        case .none:
            return .skipped("It doesn't match a booking on any of your trips")

        case .ambiguous(let matches):
            change.alternatives = matches.map {
                .init(tripID: $0.booking.tripID, itemID: $0.booking.itemID, reasons: $0.reasons)
            }
            // Offer only the bookings it would actually change.
            let probe = change
            change.alternatives.removeAll { candidate in
                guard let trip = trips.first(where: { $0.id == candidate.tripID }),
                      let item = trip.items.first(where: { $0.id == candidate.itemID }) else { return true }
                return !probe.changesAnything(item, tripCurrency: trip.currencyCode)
            }
            if change.alternatives.isEmpty { return .skipped("Your plan already matches this email") }
            if change.alternatives.count == 1, let only = change.alternatives.first {
                change.tripID = only.tripID
                change.itemID = only.itemID
                change.reasons = only.reasons
                change.alternatives = []
            }
            return .found(change)

        case .matched(let match, let certain):
            guard let trip = trips.first(where: { $0.id == match.booking.tripID }),
                  let item = trip.items.first(where: { $0.id == match.booking.itemID })
            else { return .skipped("It doesn't match a booking on any of your trips") }

            change.tripID = trip.id
            change.itemID = item.id
            change.reasons = match.reasons

            guard change.changesAnything(item, tripCurrency: trip.currencyCode) else {
                return .skipped("\(item.title) already matches this email")
            }

            // Certain needs both halves: the booking is unmistakable, and the
            // new values were *labelled* new rather than inferred.
            let labelled = facts.isCancellation || facts.hasNewSchedule || facts.revisedTotal != nil
            change.confidence = certain && labelled ? .certain : .likely
            return .found(change)
        }
    }

    // MARK: - The model's reading, verified

    /// Folds the model's answer into what the rules found, keeping only the
    /// fields found again in the email. Returns a reason when the model says
    /// this isn't a change and the rules have nothing explicit to overrule it.
    private static func merge(
        _ reading: ChangeReading,
        into facts: inout BookingMailFacts,
        text: String,
        referenceDate: Date
    ) -> String? {
        let haystack = BookingText.normalise(text)
        func verified(_ field: String) -> String? {
            let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3, haystack.contains(BookingText.normalise(trimmed)) else { return nil }
            return trimmed
        }

        if reading.outcome == .none {
            // A cancellation status phrase, or a before-and-after written out,
            // is the email being explicit — and the email beats the model.
            let explicit = facts.isCancellation || (facts.previousMinute != nil && facts.newMinute != nil)
                || (facts.previousDay != nil && facts.newDay != nil)
            if !explicit { return "Read as a notice, not a change to the booking" }
        }

        guard !facts.isCancellation else {
            if facts.refund == nil, let refund = verified(reading.refund).flatMap(amount), AmountScanner.contains(refund, in: text) {
                facts.refund = refund
            }
            return nil
        }

        if facts.newDay == nil, let raw = verified(reading.newDate) {
            facts.newDay = TravelDate.first(in: raw, referenceDate: referenceDate)
        }
        if facts.newMinute == nil, let raw = verified(reading.newTime), let clock = TravelDate.time(in: raw) {
            facts.newMinute = clock.hour * 60 + clock.minute
        }
        if facts.previousMinute == nil, let raw = verified(reading.previousTime), let clock = TravelDate.time(in: raw) {
            facts.previousMinute = clock.hour * 60 + clock.minute
        }
        if facts.revisedTotal == nil, let total = verified(reading.newTotal).flatMap(amount), AmountScanner.contains(total, in: text) {
            facts.revisedTotal = total
        }
        return nil
    }

    private static func amount(_ raw: String) -> Double? {
        Double(raw.replacingOccurrences(of: ",", with: "").filter { $0.isNumber || $0 == "." })
    }

    // MARK: - Bookings, flattened

    static func booking(for item: ItineraryItem, in trip: Trip) -> BookingMatcher.Booking {
        let minute = item.time.map {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
            return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
        let flights = BookingText.flightNumbers(in: "\(item.title) \(item.vendor)")
            .union(BookingText.flightNumbers(in: item.flight?.number.uppercased() ?? ""))
        return BookingMatcher.Booking(
            tripID: trip.id,
            itemID: item.id,
            title: item.title,
            vendor: item.vendor,
            category: item.kind.rawValue,
            day: item.day,
            minute: minute,
            flightNumbers: flights
        )
    }
}
