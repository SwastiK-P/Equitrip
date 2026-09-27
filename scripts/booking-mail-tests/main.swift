import Foundation

// MARK: - Harness

var failures = 0
var passes = 0
func check(_ condition: Bool, _ label: String, _ detail: @autoclosure () -> String = "") {
    if condition { passes += 1 } else { failures += 1; print("  ✗ \(label) \(detail())") }
}

let cal = Calendar.current
func day(_ d: Int, _ m: Int) -> Date { cal.startOfDay(for: cal.date(from: DateComponents(year: 2026, month: m, day: d))!) }
func hm(_ h: Int, _ m: Int) -> Int { h * 60 + m }
let received = cal.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 9))!

func mail(_ subject: String, _ body: String, from: String = "IndiGo <reservations@goindigo.in>", labels: [String] = ["INBOX", "CATEGORY_UPDATES"]) -> MailMessage {
    let (name, address) = MailText.splitSender(from)
    return MailMessage(id: UUID().uuidString, threadID: "t", labelIDs: labels, receivedAt: received,
                       fromName: name, fromAddress: address, subject: subject, snippet: "", body: body)
}

// MARK: - Trips: the two Kashi trips (group and solo copy) and Paris

let kashi3 = UUID(), kashi1 = UUID(), paris = UUID()

func kashiBookings(_ trip: UUID) -> [BookingMatcher.Booking] {
    func b(_ title: String, _ vendor: String, _ cat: String, _ d: Date, _ m: Int?, _ flights: Set<String> = []) -> BookingMatcher.Booking {
        .init(tripID: trip, itemID: UUID(), title: title, vendor: vendor, category: cat, day: d, minute: m, flightNumbers: flights)
    }
    return [
        b("Flight 6E 5307", "Mumbai (BOM) → Varanasi (VNS), IndiGo economy", "flight", day(28, 9), hm(7, 5), ["6E5307"]),
        b("Kashi Vishwanath Temple darshan", "Sugam Darshan tickets, Gate 4", "activity", day(28, 9), hm(10, 30)),
        b("Lunch at Kashi Chat Bhandar", "tamatar chaat, palak patta chaat, kulfi", "meal", day(28, 9), hm(13, 0)),
        b("Hotel Ganges View check-in", "Assi Ghat, 2 deluxe river-view rooms, 3 nights", "stay", day(28, 9), hm(14, 0)),
        b("Ghat heritage walk", "Assi Ghat to Dashashwamedh with local guide", "activity", day(28, 9), hm(16, 30)),
        b("Ganga Aarti boat ride", "private rowboat at Dashashwamedh Ghat", "activity", day(28, 9), hm(18, 45)),
        b("Dinner at Brown Bread Bakery", "rooftop, Bengali Tola", "meal", day(28, 9), hm(21, 0)),
        b("Sunrise boat ride", "Assi Ghat to Manikarnika Ghat, shared boat", "activity", day(29, 9), hm(5, 30)),
        b("Sarnath half-day tour", "cab and guide, Dhamek Stupa, Sarnath Museum", "activity", day(29, 9), hm(9, 30)),
        b("Bharat Kala Bhavan museum", "BHU campus, entry and audio guide", "activity", day(29, 9), hm(10, 30)),
        b("Flight 6E 2231", "Varanasi (VNS) → Mumbai (BOM)", "flight", day(1, 10), hm(18, 20), ["6E2231"]),
    ]
}

let parisBookings: [BookingMatcher.Booking] = [
    .init(tripID: paris, itemID: UUID(), title: "Flight AI 143", vendor: "Paris (CDG) → Mumbai (BOM)", category: "flight", day: day(27, 9), minute: hm(21, 30), flightNumbers: ["AI143"]),
    .init(tripID: paris, itemID: UUID(), title: "Louvre museum", vendor: "timed entry", category: "activity", day: day(27, 9), minute: hm(10, 0), flightNumbers: []),
]

let all = kashiBookings(kashi3) + kashiBookings(kashi1) + parisBookings
let people: [BookingMatcher.TripPeople] = [
    .init(tripID: kashi3, names: ["Swastik Patil", "Meenakshi", "Rohan"]),
    .init(tripID: kashi1, names: ["Swastik Patil"]),
    .init(tripID: paris, names: ["Swastik Patil"]),
]

struct Run {
    let verdict: BookingMailGate.Verdict
    let facts: BookingMailFacts
    let outcome: BookingMatcher.Outcome
}

func run(_ message: MailMessage) -> Run {
    let verdict = BookingMailGate.check(message)
    let facts = BookingMailFacts.read(message.readableText, isCancellation: verdict == .cancellation, referenceDate: message.receivedAt)
    let outcome = verdict.passed
        ? BookingMatcher.match(text: message.readableText, facts: facts, bookings: all, trips: people)
        : .none
    return Run(verdict: verdict, facts: facts, outcome: outcome)
}

func matched(_ r: Run) -> BookingMatcher.Match? {
    if case .matched(let m, _) = r.outcome { return m }
    return nil
}
func isCertain(_ r: Run) -> Bool {
    if case .matched(_, let c) = r.outcome { return c }
    return false
}
func describe(_ r: Run) -> String {
    switch r.outcome {
    case .none: return "none"
    case .matched(let m, let c): return "matched \(m.booking.title) [\(m.booking.tripID == kashi3 ? "kashi3" : m.booking.tripID == kashi1 ? "kashi1" : "paris")] score \(String(format: "%.1f", m.score)) certain=\(c) \(m.reasons)"
    case .ambiguous(let ms): return "ambiguous " + ms.map { "\($0.booking.title)@\($0.booking.tripID == kashi3 ? "k3" : $0.booking.tripID == kashi1 ? "k1" : "p") \(String(format: "%.1f", $0.score))" }.joined(separator: ", ")
    }
}

func test(_ name: String, _ message: MailMessage, _ body: (Run) -> Void) {
    let before = failures
    let r = run(message)
    body(r)
    print(failures == before ? "✓ \(name)" : "✗ \(name)\n    verdict=\(r.verdict) \(describe(r))\n    facts prev=\(r.facts.previousDay.map { "\($0)" } ?? "-") \(r.facts.previousMinute ?? -1) new=\(r.facts.newDay.map { "\($0)" } ?? "-") \(r.facts.newMinute ?? -1) stated=\(r.facts.statedDay.map { "\($0)" } ?? "-") \(r.facts.statedMinute ?? -1) revised=\(r.facts.revisedTotal ?? -1) stated$=\(r.facts.statedTotal ?? -1) refund=\(r.facts.refund ?? -1) charge=\(r.facts.cancellationCharge ?? -1) cat=\(r.facts.category ?? "-") flights=\(r.facts.flightNumbers) ref=\(r.facts.reference ?? "-")")
}

// MARK: - Cases

test("A. IndiGo reschedule, labelled old/new lines, all three passengers", mail(
    "Schedule change for your IndiGo flight 6E 5307 | PNR X7K9QP",
    """
    Dear Swastik Patil,

    Due to operational reasons, your flight 6E 5307 from Mumbai to Varanasi on 28 Sep 2026 has been rescheduled.

    Old schedule: 6E 5307 | 28 Sep 2026 | Departure 07:05 | Arrival 09:15
    New schedule: 6E 5307 | 28 Sep 2026 | Departure 09:40 | Arrival 11:50

    Passengers: Mr Swastik Patil, Ms Meenakshi, Mr Rohan

    If your flight is cancelled or rescheduled by more than 2 hours, you can opt for a full refund.
    Fare difference: ₹0
    """
)) { r in
    check(r.verdict == .change, "gate says change, not cancellation")
    check(r.facts.previousMinute == hm(7, 5), "old time 07:05")
    check(r.facts.newMinute == hm(9, 40), "new time 09:40")
    check(r.facts.newDay == day(28, 9), "new day 28 Sep")
    check(r.facts.reference == "X7K9QP", "PNR read", r.facts.reference ?? "nil")
    check(matched(r)?.booking.title == "Flight 6E 5307" && matched(r)?.booking.tripID == kashi3, "matches the group Kashi flight")
    check(isCertain(r), "certain")
}

test("B. Sentence reschedule naming only you → both Kashi trips carry it: ambiguous", mail(
    "Your flight time has changed",
    "Hi Swastik Patil, your flight 6E 5307 on 28 Sep 2026 has been rescheduled from 07:05 to 09:40. We regret the inconvenience."
)) { r in
    check(r.facts.previousMinute == hm(7, 5), "from 07:05")
    check(r.facts.newMinute == hm(9, 40), "to 09:40")
    if case .ambiguous(let ms) = r.outcome {
        check(Set(ms.prefix(2).map(\.booking.tripID)) == [kashi1, kashi3], "the two Kashi flights are the choices")
        check(ms.prefix(2).allSatisfy { $0.booking.title == "Flight 6E 5307" }, "both are the flight")
    } else { check(false, "expected ambiguous") }
}

test("C. Hotel cancellation with charge and refund", mail(
    "Booking cancelled — Hotel Ganges View, Varanasi",
    """
    Dear Swastik Patil,
    Your booking at Hotel Ganges View, Assi Ghat has been cancelled as requested.
    Booking ID: GV-88213
    Check-in: 28 Sep 2026 | Check-out: 1 Oct 2026
    Guests: Swastik Patil, Meenakshi, Rohan
    Total paid: ₹54,000
    Cancellation charges: ₹5,400
    Refund amount (after deducting cancellation charges): ₹48,600
    The refund will be credited to your original payment method within 5-7 working days.
    """,
    from: "Hotel Ganges View <stay@gangesview.in>"
)) { r in
    check(r.verdict == .cancellation, "cancellation")
    check(r.facts.refund == 48600, "refund 48,600")
    check(r.facts.cancellationCharge == 5400, "charge 5,400")
    check(r.facts.statedTotal == 54000, "total paid 54,000")
    check(r.facts.reference == "GV-88213", "booking id")
    check(matched(r)?.booking.title == "Hotel Ganges View check-in" && matched(r)?.booking.tripID == kashi3, "group trip's hotel")
}

test("D. Hotel modification: revised block, previous check-in, new total", mail(
    "Your booking has been modified",
    """
    Hello Rohan,
    Your booking at Hotel Ganges View has been modified.

    Revised booking details
    Check-in: 29 Sep 2026, 14:00
    Check-out: 1 Oct 2026, 11:00
    Rooms: 2 Deluxe River View

    Previous check-in: 28 Sep 2026
    New total: ₹58,500
    Amount paid: ₹54,000
    Balance due at hotel: ₹4,500
    """,
    from: "Hotel Ganges View <stay@gangesview.in>"
)) { r in
    check(r.verdict == .change, "change")
    check(r.facts.newDay == day(29, 9), "new check-in 29 Sep")
    check(r.facts.previousDay == day(28, 9), "previous 28 Sep")
    check(r.facts.newMinute == hm(14, 0), "time 14:00 read as the check-in, not check-out")
    check(r.facts.revisedTotal == 58500, "new total 58,500")
    check(r.facts.statedTotal == 54000, "amount paid 54,000 kept separate")
    check(matched(r)?.booking.tripID == kashi3, "Rohan is only on the group trip")
}

test("E. Operator cancels the sunrise boat ride, not the aarti boat ride", mail(
    "Update on your booking",
    "Hi Swastik, we're sorry — due to high water levels in the Ganga, your Sunrise Boat Ride (Assi Ghat to Manikarnika, 29 Sep, 5:30 AM) has been cancelled. A full refund of ₹1,600 has been initiated.",
    from: "Ghats of Kashi Tours <hello@ghatsofkashi.in>"
)) { r in
    check(r.verdict == .cancellation, "cancellation")
    check(r.facts.refund == 1600, "refund 1,600")
    switch r.outcome {
    case .matched(let m, _): check(m.booking.title == "Sunrise boat ride", "sunrise boat ride")
    case .ambiguous(let ms): check(ms.allSatisfy { $0.booking.title == "Sunrise boat ride" }, "only sunrise rides offered", describe(r))
    case .none: check(false, "expected a match")
    }
}

test("F. Confirmation with free-cancellation and modify boilerplate is not a change", mail(
    "Booking confirmed: 6E 5307 BOM-VNS",
    """
    Your booking is confirmed. PNR X7K9QP.
    Flight 6E 5307 | 28 Sep 2026 | 07:05
    Free cancellation until 25 Sep. To cancel or modify your booking visit goindigo.in.
    Cancellation/modification charges apply as per fare rules. If your flight is cancelled by us, you will get a full refund.
    """
)) { r in
    if case .rejected = r.verdict { check(true, "") } else { check(false, "should be rejected", "\(r.verdict)") }
}

test("G. Bank debit alert is not a booking change", mail(
    "Transaction alert",
    "Rs.1,200.00 has been debited from your account XX1234 to VPA kashitemple@okhdfc on 25-09-26. UPI ref 612345678901.",
    from: "HDFC Bank InstaAlerts <alerts@hdfcbank.net>"
)) { r in
    if case .rejected = r.verdict { check(true, "") } else { check(false, "should be rejected") }
}

test("H. Web check-in reminder", mail(
    "Web check-in is now open for 6E 5307",
    "Web check-in is now open for your flight 6E 5307 departing 28 Sep 2026 at 07:05. Check in now to choose your seat."
)) { r in
    if case .rejected = r.verdict { check(true, "") } else { check(false, "should be rejected") }
}

test("I. A reschedule for a flight on no trip matches nothing", mail(
    "Schedule change: 6E 6123",
    "Your flight 6E 6123 from Delhi to Goa on 3 Oct 2026 has been rescheduled from 06:00 to 08:30. Passenger: Swastik Patil."
)) { r in
    check(r.outcome == .none, "no booking", describe(r))
}

test("J. Delay notice: 'now departs … instead of'", mail(
    "Flight delay: 6E 5307",
    "Dear Customer, your flight 6E 5307 on 28 Sep 2026 is delayed. It now departs at 08:25 instead of 07:05. Passengers: Swastik Patil, Meenakshi, Rohan."
)) { r in
    check(r.verdict == .change, "change", "\(r.verdict)")
    check(r.facts.newMinute == hm(8, 25), "now 08:25")
    check(r.facts.previousMinute == hm(7, 5), "instead of 07:05")
    check(matched(r)?.booking.tripID == kashi3, "group flight")
}

test("K. HTML-table layout: headings over value lines", mail(
    "Important: change in your flight schedule",
    """
    Your flight schedule has been changed.
    Original Flight
    6E 5307
    28 Sep 2026
    07:05
    09:15
    Revised Flight
    6E 5307
    28 Sep 2026
    09:40
    11:50
    Passenger(s)
    Swastik Patil
    Meenakshi
    Rohan
    """
)) { r in
    check(r.facts.previousMinute == hm(7, 5), "original 07:05")
    check(r.facts.newMinute == hm(9, 40), "revised 09:40")
    check(r.facts.newDay == day(28, 9), "revised day")
    check(matched(r)?.booking.tripID == kashi3, "group flight")
}

test("L. Airline cancels the return flight: 'We regret to inform you…'", mail(
    "Flight cancellation notice - 6E 2231",
    "We regret to inform you that your flight 6E 2231 from Varanasi to Mumbai on 01 Oct 2026 has been cancelled due to operational reasons. A full refund of ₹21,300 will be processed. Passengers: Swastik Patil, Meenakshi, Rohan"
)) { r in
    check(r.verdict == .cancellation, "cancellation", "\(r.verdict)")
    check(r.facts.refund == 21300, "refund")
    check(matched(r)?.booking.title == "Flight 6E 2231" && matched(r)?.booking.tripID == kashi3, "return flight on group trip")
}

test("N. Refund processed later is not a new change", mail(
    "Refund processed",
    "Your refund of ₹48,600 for booking GV-88213 has been processed to your card ending 4411.",
    from: "Hotel Ganges View <stay@gangesview.in>"
)) { r in
    if case .rejected = r.verdict { check(true, "") } else { check(false, "should be rejected", "\(r.verdict)") }
}

test("O. Aarti boat ride moved earlier, booked by Meenakshi", mail(
    "Timing change for your Ganga Aarti boat ride",
    "Namaste! Your Ganga Aarti boat ride on 28 Sep has been moved to 6:15 PM (earlier 6:45 PM) as the aarti starts earlier during Navratri. Booked by: Meenakshi",
    from: "Kashi Boats <bookings@kashiboats.in>"
)) { r in
    check(r.verdict == .change, "change")
    check(r.facts.newMinute == hm(18, 15), "moved to 6:15 PM")
    check(r.facts.previousMinute == hm(18, 45), "earlier 6:45 PM")
    check(matched(r)?.booking.title == "Ganga Aarti boat ride" && matched(r)?.booking.tripID == kashi3, "aarti ride, group trip")
}

test("P. Date-only move with arrow", mail(
    "Sarnath tour rescheduled",
    "Your Sarnath half-day tour has been rescheduled. Date: 29 Sep 2026 → 30 Sep 2026. Pickup time stays 09:30 from your hotel. Lead traveller: Swastik Patil, group of 3 incl. Rohan",
    from: "Varanasi Walks <tours@varanasiwalks.com>"
)) { r in
    check(r.facts.previousDay == day(29, 9), "old 29 Sep")
    check(r.facts.newDay == day(30, 9), "new 30 Sep")
    check(r.facts.newMinute == nil, "no new time invented", "\(r.facts.newMinute ?? -1)")
    check(matched(r)?.booking.title == "Sarnath half-day tour" && matched(r)?.booking.tripID == kashi3, "Sarnath, group trip")
}

test("Q. Promotions label is rejected outright", mail(
    "Rescheduled? Book again with 20% off",
    "Your flight was rescheduled? Use code FLY20 for 20% off.",
    labels: ["CATEGORY_PROMOTIONS"]
)) { r in
    if case .rejected = r.verdict { check(true, "") } else { check(false, "should be rejected") }
}

test("R. Two flights in one mail: the wrong-flight penalty keeps the other flight off", mail(
    "Change to your return journey",
    "Your return flight 6E 2231 on 1 Oct 2026 has been rescheduled from 18:20 to 19:05. Your onward flight 6E 5307 is unchanged. Passengers: Swastik Patil, Meenakshi, Rohan",
)) { r in
    check(r.facts.newMinute == hm(19, 5) && r.facts.previousMinute == hm(18, 20), "18:20 → 19:05")
    check(matched(r)?.booking.title == "Flight 6E 2231", "the return flight is the one that moved", describe(r))
}

test("S. New Delhi isn't a 'new' time", mail(
    "Your flight has been rescheduled",
    "Flight 6E 5307 has been rescheduled. Previously departing 07:05. Connection via New Delhi 06:10 no longer applies. Revised departure 09:40. Passengers: Swastik Patil, Meenakshi, Rohan"
)) { r in
    check(r.facts.newMinute == hm(9, 40), "revised 09:40", "\(r.facts.newMinute ?? -1)")
    check(r.facts.previousMinute == hm(7, 5), "previously 07:05")
}

test("T. 'We had to cancel' is a cancellation", mail(
    "About your darshan slot",
    "Dear Rohan, we had to cancel the Sugam Darshan slot for Kashi Vishwanath Temple darshan on 28 Sep at 10:30 because of a VIP visit. ₹1,200 will be refunded.",
    from: "Shri Kashi Vishwanath Temple Trust <darshan@shrikashivishwanath.org>"
)) { r in
    check(r.verdict == .cancellation, "cancellation", "\(r.verdict)")
    check(matched(r)?.booking.title == "Kashi Vishwanath Temple darshan" && matched(r)?.booking.tripID == kashi3, "darshan, group trip", describe(r))
    check(r.facts.refund == 1200, "refund 1,200")
}

print("\n\(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
