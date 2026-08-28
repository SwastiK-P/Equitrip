//
//  TripModels.swift
//  Equitrip
//

import SwiftUI

// MARK: - Money

/// Currency lives on the trip, not the app, so a group can run a Goa trip in
/// rupees and a Bali trip in dollars without converting anything.
enum Money {
    static func format(_ amount: Double, code: String, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = amount.rounded() == amount ? 0 : 2
        formatter.locale = Locale(identifier: code == "INR" ? "en_IN" : "en_US")

        let magnitude = formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
        guard signed else { return magnitude }
        if amount > 0 { return "+" + magnitude }
        if amount < 0 { return "−" + magnitude }
        return magnitude
    }

    static func symbol(for code: String) -> String {
        switch code.uppercased() {
        case "INR": "₹"
        case "USD": "$"
        case "EUR": "€"
        case "GBP": "£"
        case "JPY": "¥"
        case "AED": "د.إ"
        case "THB": "฿"
        case "SGD": "S$"
        default: code.uppercased()
        }
    }

    static let common = ["INR", "USD", "EUR", "GBP", "AED", "THB", "SGD", "JPY"]
}

// MARK: - Itinerary kinds

/// What a booking *is*, which decides its glyph, its colour on the timeline,
/// and the default way its cost gets shared.
enum ItineraryKind: String, CaseIterable, Identifiable, Codable {
    case flight, train, drive, stay, activity, meal, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flight: "Flight"
        case .train: "Train"
        case .drive: "Transfer"
        case .stay: "Stay"
        case .activity: "Activity"
        case .meal: "Food"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .flight: "airplane"
        case .train: "tram.fill"
        case .drive: "car.fill"
        case .stay: "bed.double.fill"
        case .activity: "figure.hiking"
        case .meal: "fork.knife"
        case .other: "mappin.and.ellipse"
        }
    }

    var tint: Color {
        switch self {
        case .flight: Palette.blue
        case .train: Palette.teal
        case .drive: Palette.indigo
        case .stay: Palette.violet
        case .activity: Palette.green
        case .meal: Palette.amber
        case .other: Palette.stone
        }
    }

    var defaultSplit: SplitMode {
        switch self {
        // A room is shared by whoever is in it, which is what "only
        // participants" already means — the old `.room` mode was the same rule
        // under a different name.
        case .stay: .participants
        case .activity: .participants
        default: .equal
        }
    }
}

// MARK: - Cost sharing

/// The models the brief calls for. Each one answers "whose cost is this?"
/// differently, which is the whole reason a group ledger is hard.
enum SplitMode: String, CaseIterable, Identifiable, Codable {
    case equal
    case participants
    /// Everyone named pays a figure somebody typed. The only mode where the
    /// shares aren't derived from the cost.
    case custom
    case organiser
    case individual

    var id: String { rawValue }

    /// Reads a stored value, including ones this app no longer offers.
    ///
    /// `room` was a sixth mode meaning "divided across each room's occupants",
    /// and it never did that — there is no concept of a room anywhere in the
    /// model, so `bearers(of:)` handled it identically to `participants`. It
    /// was a button that duplicated the button next to it. Rows written before
    /// it was dropped land on the mode it was actually behaving as, so nobody's
    /// existing arithmetic changes.
    static func decode(_ raw: String) -> SplitMode {
        if raw == "room" { return .participants }
        return SplitMode(rawValue: raw) ?? .equal
    }

    var label: String {
        switch self {
        case .equal: "Split equally"
        case .participants: "Only participants"
        case .custom: "Exact amounts"
        case .organiser: "Organiser pays"
        case .individual: "One person"
        }
    }

    /// Fits a tile; `label` is the full sentence for lists and summaries.
    var shortLabel: String {
        switch self {
        case .equal: "Equally"
        case .participants: "Participants"
        case .custom: "Exact"
        case .organiser: "Organiser"
        case .individual: "One person"
        }
    }

    var detail: String {
        switch self {
        case .equal: "Divided evenly across everyone on the trip, whether or not they're on this booking"
        case .participants: "Divided evenly, but only across the people named on this booking"
        case .custom: "You set what each person owes. The amounts have to add up to the cost"
        case .organiser: "Carried by whoever is organising the trip, not shared out"
        case .individual: "One named person carries the whole cost"
        }
    }

    var symbol: String {
        switch self {
        case .equal: "equal"
        case .participants: "person.2.fill"
        case .custom: "slider.horizontal.3"
        case .organiser: "star.fill"
        case .individual: "person.fill"
        }
    }

    /// Whether this mode wants exactly one person named, rather than a set.
    var isSinglePerson: Bool { self == .individual }

    /// Whether the shares are typed rather than computed.
    var isCustom: Bool { self == .custom }
}

// MARK: - Paying

/// How a booking was actually settled with the vendor.
///
/// Separate from the split, and easy to confuse with it: the split says whose
/// cost this is, the method says how the money left somebody's hands. Only
/// the second one can produce a receipt, which is why `isOnline` exists — a
/// cash dinner has nothing to photograph, an online booking has a
/// confirmation everybody else on the item will eventually want to see.
enum PaymentMethod: String, CaseIterable, Identifiable, Codable {
    case cash, upi, card, transfer, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cash: "Cash"
        case .upi: "UPI"
        case .card: "Card"
        case .transfer: "Bank transfer"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cash: "banknote"
        case .upi: "indianrupeesign.circle"
        case .card: "creditcard"
        case .transfer: "building.columns"
        case .other: "ellipsis.circle"
        }
    }

    /// Whether there's a confirmation worth attaching. Cash leaves no trail
    /// worth photographing; everything else does.
    var isOnline: Bool { self != .cash }
}

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
        createdAt: Date = Date()
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

// MARK: - Trip

struct Trip: Identifiable {
    enum Phase {
        case upcoming, live, past

        var label: String {
            switch self {
            case .upcoming: "Upcoming"
            case .live: "In progress"
            case .past: "Wrapped up"
            }
        }

        var tint: Color {
            switch self {
            case .live: AppTheme.positive
            case .upcoming: AppTheme.accent
            case .past: AppTheme.inkTertiary
            }
        }
    }

    let id: UUID
    var title: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var currencyCode: String
    var symbol: String
    var tint: Color
    var travellers: [Traveller]
    var items: [ItineraryItem]
    /// Who can edit the trip. Usually the person who made it, but a long trip
    /// is rarely organised alone — the flights are someone's job and the
    /// villa is someone else's — so this is a set rather than a single holder.
    var organiserIDs: Set<UUID>
    /// Resolved once from the photo service and kept, so the cover doesn't
    /// change every time the card scrolls back on screen.
    var cover: TripPhoto?

    /// What the bookings add up to when we can't see the bookings.
    ///
    /// Only ever set on the join preview. Row-level security hides
    /// `itinerary_items` from anyone who isn't on the trip yet — correctly, a
    /// stranger with a code shouldn't get the itinerary — so the preview asked
    /// for bookings it was never going to be shown and reported "0 bookings,
    /// ₹0" for a fully-planned trip. The server hands over the two aggregates
    /// instead, and these carry them.
    var previewBookingCount: Int?
    var previewCost: Double?

    init(
        id: UUID = UUID(),
        title: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        currencyCode: String = "INR",
        symbol: String = "suitcase.fill",
        tint: Color = AppTheme.accent,
        travellers: [Traveller] = [],
        items: [ItineraryItem] = [],
        organiserIDs: Set<UUID>? = nil,
        cover: TripPhoto? = nil,
        previewBookingCount: Int? = nil,
        previewCost: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.currencyCode = currencyCode
        self.symbol = symbol
        self.tint = tint
        self.travellers = travellers
        self.items = items
        // Whoever created it organises until they add someone else.
        self.organiserIDs = organiserIDs ?? Set([travellers.first?.id].compactMap { $0 })
        self.cover = cover
        self.previewBookingCount = previewBookingCount
        self.previewCost = previewCost
    }

    // MARK: Derived

    var dateRange: String {
        let calendar = Calendar.current
        let sameMonth = calendar.isDate(startDate, equalTo: endDate, toGranularity: .month)
        let start = DateFormatter.cached(sameMonth ? "d" : "d MMM").string(from: startDate)
        let end = DateFormatter.cached("d MMM").string(from: endDate)
        return "\(start)–\(end)"
    }

    var dayCount: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days + 1)
    }

    var phase: Phase {
        let today = Calendar.current.startOfDay(for: Date())
        if today < Calendar.current.startOfDay(for: startDate) { return .upcoming }
        if today > Calendar.current.startOfDay(for: endDate) { return .past }
        return .live
    }

    /// Days elapsed for a live trip; how much of the plan is booked otherwise.
    var progress: Double {
        switch phase {
        case .upcoming:
            return items.isEmpty ? 0.04 : min(1, Double(items.count) / Double(max(dayCount * 2, 1)))
        case .live:
            let elapsed = Calendar.current.dateComponents(
                [.day], from: Calendar.current.startOfDay(for: startDate), to: Date()
            ).day ?? 0
            return min(1, Double(elapsed + 1) / Double(dayCount))
        case .past:
            return 1
        }
    }

    var progressLabel: String {
        switch phase {
        case .upcoming:
            return bookingCount == 0 ? "Nothing booked yet" : "\(bookingCount) booked"
        case .live:
            let elapsed = Calendar.current.dateComponents(
                [.day], from: Calendar.current.startOfDay(for: startDate), to: Date()
            ).day ?? 0
            return "Day \(min(dayCount, elapsed + 1)) of \(dayCount)"
        case .past:
            return bookingCount.pluralised("booking")
        }
    }

    /// How many bookings there are, whether or not we're allowed to see them.
    var bookingCount: Int { previewBookingCount ?? items.count }

    /// What the trip is on course to cost, everything currently booked added
    /// up. Deliberately not "total": bookings keep arriving right up to the
    /// last day, so this is a running forecast and the word should say so.
    var projectedCost: Double { previewCost ?? items.reduce(0) { $0 + $1.cost } }
    var projectedLabel: String { Money.format(projectedCost, code: currencyCode) }

    // MARK: Ledger

    /// Whether the money side means anything yet.
    ///
    /// Two conditions, and the second is the one that does the work. A balance
    /// of zero is drawn as "Settled · all square", which reads as a fact — we
    /// went, we paid, we're square — when in fact it's the absence of one.
    /// Before the first day that's simply wrong, and it's just as wrong on day
    /// one of a trip where nobody has recorded paying for anything yet. Until
    /// there's a payment in the ledger the useful figure is what the trip is
    /// going to cost you.
    var showsBalance: Bool {
        phase != .upcoming && items.contains { $0.paidByID != nil }
    }

    /// Who a booking's cost actually lands on, by its sharing rule.
    ///
    /// The one place this is decided. It used to be spelled out separately in
    /// the timeline row, the detail sheet, the editor's note and the trip
    /// summary, which is why the four of them could disagree about the same
    /// booking.
    func bearers(of item: ItineraryItem) -> [Traveller] {
        switch item.split {
        case .equal:
            return travellers
        case .participants:
            return participants(of: item)
        case .custom:
            // Only the people actually given an amount. Someone named on the
            // booking who was assigned nothing owes nothing — which is the
            // whole point of typing the figures in.
            return participants(of: item).filter { (item.customShares[$0.id] ?? 0) > 0 }
        case .organiser:
            return organisers.isEmpty ? travellers : organisers
        case .individual:
            // Exactly one person, and no falling back to "everyone" — an
            // individual cost charged to the whole group is the opposite of
            // what was asked for.
            if let named = travellers.first(where: { item.participantIDs.contains($0.id) }) { return [named] }
            return item.paidByID.flatMap(traveller).map { [$0] } ?? []
        }
    }

    /// What each person owes on one booking. Empty when nobody bears it.
    func shares(of item: ItineraryItem) -> [(traveller: Traveller, amount: Double)] {
        // Typed amounts are read back exactly as typed. Everything else is the
        // cost over the heads it lands on.
        if item.split.isCustom {
            return bearers(of: item).map { ($0, item.customShares[$0.id] ?? 0) }
        }

        let people = bearers(of: item)
        guard !people.isEmpty else { return [] }
        let each = item.cost / Double(people.count)
        return people.map { ($0, each) }
    }

    func share(of item: ItineraryItem, for travellerID: UUID) -> Double {
        shares(of: item).first { $0.traveller.id == travellerID }?.amount ?? 0
    }

    /// What one person laid out on the group's behalf.
    func paid(by travellerID: UUID) -> Double {
        items.filter { $0.paidByID == travellerID }.reduce(0) { $0 + $1.cost }
    }

    /// What the whole trip costs one person, paid for or not. This is their
    /// share of the plan, which is a different question from what they owe.
    func cost(for travellerID: UUID) -> Double {
        items.reduce(0) { $0 + share(of: $1, for: travellerID) }
    }

    /// What one person owes. Only bookings somebody has actually paid for
    /// count: until money has changed hands a booking is a plan, not a debt,
    /// and charging people for a hotel nobody has paid yet is how a ledger
    /// ends up disagreeing with everyone's bank statement.
    func owed(by travellerID: UUID) -> Double {
        items.filter { $0.paidByID != nil }.reduce(0) { $0 + share(of: $1, for: travellerID) }
    }

    /// What the rest of the group owes this person: everything they laid out,
    /// less their own share of it.
    func owedTo(_ travellerID: UUID) -> Double {
        items
            .filter { $0.paidByID == travellerID }
            .reduce(0) { $0 + ($1.cost - share(of: $1, for: travellerID)) }
    }

    /// What this person owes the people who paid for things they're on.
    func owing(_ travellerID: UUID) -> Double {
        items
            .filter { $0.paidByID != nil && $0.paidByID != travellerID }
            .reduce(0) { $0 + share(of: $1, for: travellerID) }
    }

    /// Laid out minus owed. Positive means the group owes them. Equal to
    /// `owedTo` minus `owing`, by construction.
    func balance(for travellerID: UUID) -> Double {
        paid(by: travellerID) - owed(by: travellerID)
    }

    /// Your position on this trip, which is what every card leads with.
    ///
    /// Computed from the bookings rather than stored: it used to be a stored
    /// zero that every code path faithfully carried around, so the app could
    /// only ever say "Settled".
    var netBalance: Double { balance(for: Traveller.you.id) }

    var netLabel: String {
        netBalance == 0 ? "Settled" : Money.format(netBalance, code: currencyCode, signed: true)
    }

    var netCaption: String {
        if netBalance > 0 { return "you get back" }
        if netBalance < 0 { return "you owe" }
        return "all square"
    }

    var netTone: Color {
        if netBalance > 0 { return AppTheme.moneyIn }
        if netBalance < 0 { return AppTheme.moneyOut }
        return AppTheme.moneyFlat
    }

    /// What the trip costs you, whether or not anyone has paid yet — the
    /// figure that's worth showing before the balance means anything.
    var yourShare: Double { cost(for: Traveller.you.id) }

    /// Items grouped into days, in order — the timeline's backing data.
    var days: [TripDay] {
        let grouped = Dictionary(grouping: items.sorted(by: Self.chronological)) { $0.day }
        return grouped.keys.sorted().enumerated().map { index, day in
            TripDay(index: index, date: day, items: grouped[day] ?? [])
        }
    }

    /// The next few things happening, for Home's "Up next".
    func upcoming(limit: Int = 3) -> [ItineraryItem] {
        let now = Date()
        let ahead = items
            .filter { ($0.time ?? $0.date.endOfDay) >= now }
            .sorted(by: Self.chronological)
        return Array((ahead.isEmpty ? items.sorted(by: Self.chronological) : ahead).prefix(limit))
    }

    func traveller(_ id: UUID) -> Traveller? { travellers.first { $0.id == id } }

    var organisers: [Traveller] { travellers.filter { organiserIDs.contains($0.id) } }

    /// Only organisers edit. Everyone else sees the plan read-only, which is
    /// the point of having one.
    var youAreOrganiser: Bool { organiserIDs.contains(Traveller.you.id) }

    /// The code someone types to join. Derived from the trip's id so it's
    /// stable without needing to be stored, and shaped to be read aloud:
    /// uppercase, no vowels (so no accidental words), no 0/O or 1/I.
    ///
    /// Built from the UUID's raw bytes rather than its `hashValue`. Swift
    /// seeds hashing per process, so a hash-derived code changed every launch
    /// — the same trip would hand out an invite that stopped working the next
    /// time the app opened.
    var inviteCode: String {
        let alphabet = Array("ACDEFGHJKLMNPQRTUVWXY3456789")
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        var code = ""

        for index in 0..<6 {
            if index == 3 { code += "-" }
            // Two bytes per character, so the whole id contributes rather
            // than just its first six bytes.
            let value = Int(bytes[index * 2]) << 8 | Int(bytes[index * 2 + 1])
            code.append(alphabet[value % alphabet.count])
        }
        return code
    }

    /// What the QR encodes.
    ///
    /// A custom scheme rather than an https link: a universal link needs an
    /// `apple-app-site-association` file served from a domain we control, and
    /// without one an https QR just opens Safari on a dead page. iOS Camera
    /// and most scanner apps offer to open a registered custom scheme
    /// directly, which is the behaviour actually wanted here.
    var inviteLink: URL? {
        URL(string: "equitrip://join/\(Trip.normaliseCode(inviteCode))")
    }

    /// Codes are shown hyphenated and compared without — so a typed "am9pxq"
    /// and a scanned "AM9-PXQ" reach the same trip.
    static func normaliseCode(_ raw: String) -> String {
        raw.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    /// How many characters an invite code actually carries. `inviteCode`
    /// builds exactly this many; anything longer is a typo or a paste of
    /// something else.
    static let codeLength = 6

    /// Reformats a raw code back into the grouped form for display.
    ///
    /// Truncates to `codeLength`. The field re-formats itself on every
    /// keystroke, and letting it grow without bound meant a stray paste could
    /// leave a string the lookup would never match, with no hint as to why.
    static func formatCode(_ raw: String) -> String {
        let clean = String(normaliseCode(raw).prefix(codeLength))
        guard clean.count > 3 else { return clean }
        let split = clean.index(clean.startIndex, offsetBy: 3)
        return "\(clean[..<split])-\(clean[split...])"
    }

    func participants(of item: ItineraryItem) -> [Traveller] {
        let picked = travellers.filter { item.participantIDs.contains($0.id) }
        // An item with nobody named is a whole-group cost, not an empty one.
        return picked.isEmpty ? travellers : picked
    }

    static func chronological(_ a: ItineraryItem, _ b: ItineraryItem) -> Bool {
        let lhs = a.time ?? a.date
        let rhs = b.time ?? b.date
        if a.day != b.day { return a.day < b.day }
        return lhs < rhs
    }
}

struct TripDay: Identifiable {
    let index: Int
    let date: Date
    let items: [ItineraryItem]

    var id: Date { date }
    var title: String { "Day \(index + 1)" }
    var subtitle: String { DateFormatter.cached("EEE d MMM").string(from: date) }
    var isToday: Bool { Calendar.current.isDateInToday(date) }
}

// MARK: - Flight tracking

/// What live lookup adds on top of a manually entered flight: the route,
/// scheduled times as the airline states them, and whether it's running to
/// plan. The flight number is the only field that's ever hand-typed —
/// everything else here comes from a lookup, boarding-pass scan included.
struct FlightDetails: Hashable, Codable {
    enum Status: String, Codable {
        case scheduled, active, landed, delayed, cancelled, unknown

        var label: String {
            switch self {
            case .scheduled: "Scheduled"
            case .active: "In the air"
            case .landed: "Landed"
            case .delayed: "Delayed"
            case .cancelled: "Cancelled"
            case .unknown: "Status unknown"
            }
        }

        var tint: Color {
            switch self {
            case .scheduled: AppTheme.inkSecondary
            case .active: Palette.blue
            case .landed: AppTheme.positive
            case .delayed: Palette.amber
            case .cancelled: AppTheme.danger
            case .unknown: AppTheme.inkTertiary
            }
        }
    }

    /// As entered or scanned, e.g. "6E 5312". Kept exactly as typed so it
    /// still displays sensibly even when a lookup never resolves it.
    var number: String
    var airlineName: String?

    var departureAirport: String?
    /// Full airport name, which is what people actually recognise — "JFK"
    /// alone means nothing to most of a group.
    var departureAirportName: String?
    var departureCity: String?
    var departureTerminal: String?
    var departureGate: String?

    var arrivalAirport: String?
    var arrivalAirportName: String?
    var arrivalCity: String?
    var arrivalTerminal: String?

    var scheduledDeparture: Date?
    var scheduledArrival: Date?
    /// Minutes late at the gate, when the airline admits to any.
    var departureDelay: Int?

    var status: Status?
    /// Nil until a lookup has actually run — distinguishes "haven't checked"
    /// from "checked and the airline gave nothing back".
    var lastChecked: Date?

    var isResolved: Bool { lastChecked != nil }

    /// The single line a boarding-pass-style card leads with. Falls back
    /// through the identifiers we actually have rather than showing "—".
    var displayAirline: String {
        airlineName ?? "Flight"
    }

    /// Countdown to the gate, but only while it's still ahead and close
    /// enough to matter — "departs in 84 days" is noise, not information.
    func departsIn(from now: Date = Date()) -> String? {
        guard let scheduledDeparture else { return nil }
        let seconds = scheduledDeparture.timeIntervalSince(now)
        guard seconds > 0, seconds < 60 * 60 * 48 else { return nil }

        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

// MARK: - Photos

/// A resolved photo plus the credit its licence requires us to show.
struct TripPhoto: Hashable, Codable {
    var url: URL
    var thumbURL: URL?
    var photographer: String
    var photographerURL: URL?
    var sourceName: String
}

// MARK: - Ledger activity

struct ActivityEvent: Identifiable {
    /// Raw-valued so it round-trips through `notifications.kind`, which is a
    /// plain text column rather than an enum type — the set of things worth
    /// telling someone about grows faster than a migration can keep up with.
    ///
    /// That column being plain text is also why new cases can be added without
    /// a migration: `NotificationRow.asNotification` falls back to `.booking`
    /// for anything it doesn't recognise, so an older build reading a newer
    /// event shows it with the wrong glyph rather than dropping it.
    enum Kind: String, CaseIterable {
        case payment, recalculation, refund, joined, booking
        /// A booking's details moved under people who'd already planned round
        /// them — a time, a price, who's on it.
        case bookingChanged = "booking_changed"
        /// A booking that no longer exists. Distinct from a refund: the money
        /// may never have been spent, but the plan definitely changed.
        case bookingRemoved = "booking_removed"
        /// Someone agreed a payment happened as recorded.
        case confirmed
        /// Someone said it didn't. The whole point of `confirmed` existing.
        case disputed

        var symbol: String {
            switch self {
            case .payment: "arrow.up.right"
            case .recalculation: "arrow.triangle.2.circlepath"
            case .refund: "arrow.uturn.backward"
            case .joined: "person.badge.plus"
            case .booking: "checkmark"
            case .bookingChanged: "pencil"
            case .bookingRemoved: "trash"
            case .confirmed: "checkmark.seal.fill"
            case .disputed: "exclamationmark.bubble.fill"
            }
        }

        var tint: Color {
            switch self {
            case .payment: AppTheme.accent
            case .recalculation: Palette.amber
            case .refund: AppTheme.positive
            case .joined: Palette.violet
            case .booking: Palette.blue
            case .bookingChanged: Palette.amber
            case .bookingRemoved: AppTheme.danger
            case .confirmed: AppTheme.positive
            case .disputed: AppTheme.danger
            }
        }

        /// Which switch in Settings governs this event. Several kinds share
        /// one — nobody wants four separate toggles for "a booking changed".
        var channel: NotificationChannel {
            switch self {
            case .payment, .refund, .confirmed, .disputed: .payments
            case .booking, .bookingChanged, .bookingRemoved: .bookings
            case .joined: .people
            case .recalculation: .balances
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let actor: String
    let detail: String
    let context: String
    let amount: String?
    let amountTone: Color
}

// MARK: - Notifications

/// The switches in Settings, and what each one covers.
///
/// Grouped by the question being answered rather than by event type: "tell me
/// when money moves" is a thing somebody wants; "tell me about
/// `booking_changed` but not `booking_removed`" is not.
enum NotificationChannel: String, CaseIterable, Identifiable {
    case payments, bookings, people, balances

    var id: String { rawValue }

    var title: String {
        switch self {
        case .payments: "Payments"
        case .bookings: "Bookings"
        case .people: "People"
        case .balances: "Balance changes"
        }
    }

    var detail: String {
        switch self {
        case .payments: "Someone paid, confirmed or disputed"
        case .bookings: "Added, changed or removed"
        case .people: "Joined or left a trip"
        case .balances: "Shares recalculated"
        }
    }

    var symbol: String {
        switch self {
        case .payments: "creditcard"
        case .bookings: "calendar"
        case .people: "person.2"
        case .balances: "arrow.triangle.2.circlepath"
        }
    }

    /// Muting is a per-device preference, not a row on the server: the same
    /// account on a phone and an iPad can reasonably want different noise.
    private var key: String { "notify.\(rawValue)" }

    var isOn: Bool {
        get {
            // Absent means on. A channel nobody has touched should deliver,
            // and `bool(forKey:)` answers false for a key that was never set.
            UserDefaults.standard.object(forKey: key) as? Bool ?? true
        }
        nonmutating set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct AppNotification: Identifiable {
    /// What you said about a payment somebody else recorded.
    ///
    /// Held on the notification rather than on the booking on purpose. The
    /// booking records what was paid; this records whether the people it
    /// landed on *agree*, and those are different claims — one person
    /// disputing a payment shouldn't rewrite the ledger out from under
    /// everyone else, it should start a conversation.
    enum Response: String {
        case confirmed, disputed

        var label: String { self == .confirmed ? "Confirmed" : "Disputed" }
        var symbol: String { self == .confirmed ? "checkmark.seal.fill" : "exclamationmark.bubble.fill" }
        var tint: Color { self == .confirmed ? AppTheme.positive : AppTheme.danger }
        var event: ActivityEvent.Kind { self == .confirmed ? .confirmed : .disputed }
    }

    let id: UUID
    let kind: ActivityEvent.Kind
    let title: String
    let body: String
    let date: Date
    /// Mutable: the point of a notification list is that it stops shouting
    /// once you've read it.
    var isUnread: Bool
    /// Which trip it belongs to, so tapping one can open it.
    var tripID: UUID?
    /// Your answer, when this is a payment that wanted one. Stored on device —
    /// see `NotificationStore.responses` — because the `notifications` table
    /// has no column for it and the answer is worth keeping either way.
    var response: Response?

    init(
        id: UUID = UUID(),
        kind: ActivityEvent.Kind,
        title: String,
        body: String,
        date: Date = Date(),
        isUnread: Bool = true,
        tripID: UUID? = nil,
        response: Response? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.date = date
        self.isUnread = isUnread
        self.tripID = tripID
        self.response = response
    }

    /// Whether this is asking you something. A payment somebody else recorded
    /// is a claim on your share, so it gets two buttons rather than being
    /// filed silently; everything else is news, and news doesn't need an
    /// answer.
    var needsResponse: Bool { kind == .payment && response == nil && tripID != nil }

    var time: String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h ago" }
        if seconds < 172_800 { return "Yesterday" }
        return "\(Int(seconds / 86_400))d ago"
    }
}

// MARK: - Quick actions

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
}

extension QuickAction {
    static let all: [QuickAction] = [
        .init(title: "Expense", symbol: "plus"),
        .init(title: "Payment", symbol: "arrow.left.arrow.right"),
        .init(title: "New trip", symbol: "suitcase"),
        // Chat, not Invite: inviting is a once-per-trip act that lives on the
        // trip itself, while the conversation is the thing you reach for daily.
        .init(title: "Chat", symbol: "message")
    ]
}

// MARK: - Date helpers

extension DateFormatter {
    /// Formatters are expensive to build and these run inside list rows.
    static func cached(_ format: String) -> DateFormatter {
        if let existing = cache[format] { return existing }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        cache[format] = formatter
        return formatter
    }

    private nonisolated(unsafe) static var cache: [String: DateFormatter] = [:]
}

extension Int {
    /// "1 booking", "3 bookings". Counts and their nouns kept disagreeing in
    /// the copy — "1 travellers" — because every call site spelled the plural
    /// out by hand and none of them handled one.
    func pluralised(_ singular: String, _ plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : plural ?? singular + "s")"
    }
}

extension Date {
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    static func at(_ hour: Int, _ minute: Int, on day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    static func daysFromToday(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }
}
