//
//  Trip.swift
//  Equitrip
//

import SwiftUI

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
    /// Direct transfers between travellers, outside any one booking. See
    /// `SettlementEngine` — this is the raw record; the minimised "who pays
    /// whom" list is computed from it plus the booking ledger.
    var settlements: [Settlement]
    /// People who have left, and the frozen arithmetic that closed their side
    /// of the trip. See `TripDeparture` — nobody is ever removed from
    /// `travellers`, because the ledger points at them from both directions;
    /// they acquire an end date instead.
    var departures: [TripDeparture]
    /// People who have been asked and haven't answered yet.
    ///
    /// They're in `travellers` — the organiser who invited them needs to see
    /// them on the list, marked as pending — but they are on the trip in name
    /// only until they accept. `bearers(of:)` skips them entirely, so an
    /// invitation changes nobody's share of anything. That's the whole point:
    /// being on a trip means owing money, and nobody should be made to owe
    /// money by somebody else typing their email address.
    var invitedIDs: Set<UUID>
    /// Who can edit the trip. Usually the person who made it, but a long trip
    /// is rarely organised alone — the flights are someone's job and the
    /// villa is someone else's — so this is a set rather than a single holder.
    var organiserIDs: Set<UUID>
    /// Resolved once from the photo service and kept, so the cover doesn't
    /// change every time the card scrolls back on screen.
    var cover: TripPhoto?
    /// The typeface the trip's name is set in. See `TripTitleStyle`.
    var titleStyle: TripTitleStyle

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
        settlements: [Settlement] = [],
        departures: [TripDeparture] = [],
        invitedIDs: Set<UUID> = [],
        organiserIDs: Set<UUID>? = nil,
        cover: TripPhoto? = nil,
        titleStyle: TripTitleStyle = .classic,
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
        self.settlements = settlements
        self.departures = departures
        self.invitedIDs = invitedIDs
        // Whoever created it organises until they add someone else.
        self.organiserIDs = organiserIDs ?? Set([travellers.first?.id].compactMap { $0 })
        self.cover = cover
        self.titleStyle = titleStyle
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
        let candidates = candidateBearers(of: item)

        // Anybody whose confirmed departure took them off this booking drops
        // out here, and *only* here — which is what keeps a mid-trip exit from
        // leaking into arithmetic nobody thought to check. See `carries`.
        //
        // Invitees drop out for the simpler reason that they aren't on the
        // trip yet. Both ends of the membership lifecycle meet in this one
        // filter, which is why neither can leak into the ledger by accident.
        let present = candidates.filter { !invitedIDs.contains($0.id) && carries(item, $0.id) }

        // Never empty out a booking that had bearers. A cost divided across
        // nobody is a cost that lands on nobody, and the payer is then owed
        // money that no one owes — the balances stop summing to zero and
        // `SettlementEngine` starts handing out transfers that can't clear.
        // Falling back to the unfiltered set keeps the invariant that every
        // booking's shares add up to its cost, which is worth more than
        // honouring a departure on an edge case that shouldn't arise.
        return present.isEmpty ? candidates : present
    }

    /// Who would bear this booking if nobody had ever left — the sharing rule
    /// on its own, before membership dates are applied.
    private func candidateBearers(of item: ItineraryItem) -> [Traveller] {
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

        // Whole units only. The payer carries the leftover when they're on the
        // booking — they're owed it back anyway, so everyone else's figure
        // stays a round number.
        let people = bearers(of: item)
        guard !people.isEmpty else { return [] }
        let holder = people.firstIndex { $0.id == item.paidByID } ?? 0
        let parts = Money.evenSplit(item.cost, heads: people.count, holder: holder)
        return zip(people, parts).map { ($0, $1) }
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
    ///
    /// Leaving gives up the pen. Someone who has gone home keeps every read —
    /// they can still see what they owe and still settle it — but a trip
    /// they're no longer on isn't theirs to re-plan, and an organiser who left
    /// on day three quietly retaining edit rights over the last four days is
    /// not something anyone would expect.
    var youAreOrganiser: Bool {
        organiserIDs.contains(Traveller.you.id) && !hasLeft(Traveller.you.id)
    }

    /// Anyone still on the trip can add a booking or expense. Invited people
    /// couldn't, because this used to be `youAreOrganiser` — yet RLS
    /// (`items_write_active`) already lets every active member write items.
    /// Trip-level edits (title, dates, roles) stay organiser-only.
    var youCanAddBookings: Bool {
        travellers.contains { $0.id == Traveller.you.id } && !hasLeft(Traveller.you.id)
    }

    /// Organisers edit any booking; everyone else edits the ones they added.
    func youCanEdit(_ item: ItineraryItem) -> Bool {
        youAreOrganiser || (youCanAddBookings && item.createdByID == Traveller.you.id)
    }

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

// MARK: - Photos

/// A resolved photo plus the credit its licence requires us to show.
struct TripPhoto: Hashable, Codable {
    var url: URL
    var thumbURL: URL?
    var photographer: String
    var photographerURL: URL?
    var sourceName: String
}
