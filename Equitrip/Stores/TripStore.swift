//
//  TripStore.swift
//  Equitrip
//

import SwiftUI
import Supabase

/// Single source of truth for trips, backed entirely by Supabase.
///
/// Screens read from here and the creation flow writes to it, so a trip made
/// on Tuesday shows up on Home, in the tab bar and on the timeline at once.
/// It starts *empty* and stays empty until the server answers — there is no
/// local sample data behind it any more. That matters beyond tidiness: the
/// old samples were rebuilt with fresh UUIDs on every launch, so a trip you
/// were looking at had a different identity each time the app started, and
/// anything keyed to it server-side (chat above all) could never be read back.
@MainActor
@Observable
final class TripStore {

    /// What the trip list currently is. `.loading` and an empty `.ready` are
    /// different screens — "we haven't asked yet" and "you're on no trips" ask
    /// completely different things of the person looking at them.
    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)

        var isLoading: Bool { self == .loading }
        var failure: String? { if case let .failed(message) = self { message } else { nil } }
    }

    /// Every mutation republishes the widget snapshot.
    ///
    /// On the property rather than at the two dozen call sites that change it:
    /// a booking edited in the timeline, a settlement confirmed over realtime
    /// and a sync landing all move the same numbers, and the one that gets
    /// forgotten is always the one somebody notices on their home screen.
    /// `WidgetPublisher` drops a write whose figures are unchanged, so this
    /// costs nothing on the passes that only moved a cover photo.
    private(set) var trips: [Trip] {
        didSet {
            WidgetPublisher.publish(trips)
            // The semantic index Siri, Spotlight and Equi search. Same
            // reasoning as the widgets: on the property, so no change escapes.
            SpotlightIndex.publish(trips)
        }
    }

    private(set) var state: LoadState = .loading

    /// The last write that didn't make it. Separate from `state`, which is
    /// about reading — "we couldn't load your trips" and "we couldn't save
    /// this one" need different words and only one of them should ever be on
    /// screen at a time.
    private(set) var writeFailure: String?

    /// Trips created on this device whose upsert hasn't come back yet. `sync`
    /// preserves these: replacing the list wholesale while a create was still
    /// in flight is what made a brand-new trip vanish a second after it was
    /// made.
    private var unsynced: Set<UUID> = []

    /// The trip the Expenses and Settle tabs are scoped to.
    var selectedTripID: UUID?

    /// Navigation stack for the Itinerary tab. Home pushes onto this when a
    /// trip is opened from there, so "open this trip" and "browse to it" land
    /// in the same place instead of two parallel screens.
    var itineraryPath: [ItineraryRoute] = []

    /// Who to tell when something on a trip moves.
    ///
    /// Wired up by `RootTabView` rather than resolved from the environment,
    /// because the announcements have to fire from the mutations themselves.
    /// Every screen that adds, edits or deletes a booking would otherwise have
    /// to remember to announce it too, and the ones that forgot were exactly
    /// the ones where a change went unnoticed. `@ObservationIgnored` because
    /// this is a collaborator, not state anything renders.
    @ObservationIgnored weak var notifier: NotificationStore?

    /// Where every change to a trip gets written down.
    ///
    /// Wired here rather than at the screens for the same reason as `notifier`,
    /// only more so: a notification somebody forgot to send is a message that
    /// didn't arrive, but an audit entry somebody forgot to file is a hole in
    /// the record — and a record with holes in it is not one anybody can point
    /// at during a disagreement. Every mutation on this type files one, which
    /// is the only way to be sure they all do.
    @ObservationIgnored weak var auditor: AuditTrail?

    /// Who to pop a toast in front of when a settlement changes somewhere
    /// else. Same reasoning as `notifier`: wired from the root rather than
    /// resolved from the environment, because the realtime handler that fires
    /// it isn't a view.
    @ObservationIgnored weak var toaster: ToastCenter?

    /// The live channel for `public.settlements`. Global rather than
    /// per-trip — unlike chat, which only matters while its screen is open, a
    /// settlement request has to reach you wherever you are in the app, so it
    /// subscribes once at launch and stays up for the session.
    @ObservationIgnored private var settlementChannel: RealtimeChannelV2?
    @ObservationIgnored private var settlementTasks: [Task<Void, Never>] = []

    private var client: SupabaseClient { AuthService.shared.client }

    init(trips: [Trip] = []) {
        self.trips = trips
        self.selectedTripID = trips.first(where: { $0.phase == .live })?.id ?? trips.first?.id
        self.state = trips.isEmpty ? .loading : .ready
    }

    /// Pulls the whole graph down from Postgres.
    ///
    /// An empty result is a success — it means you're on no trips yet, and the
    /// screens have an empty state that says so. Only a thrown error becomes
    /// `.failed`, and it keeps whatever is already on screen rather than
    /// blanking it, so a dropped connection mid-session doesn't wipe the view.
    ///
    /// Siri passes `includeInvitations: false`: nothing it answers reads them,
    /// and a cold launch behind a spoken question has no round trip to spare.
    func sync(includeInvitations: Bool = true) async {
        if trips.isEmpty { state = .loading }

        do {
            let remote = try await SupabaseRepository.shared.loadTrips()
            let arrived = Set(remote.map(\.id))

            // Anything still on its way to the server stays put, and stops
            // being "unsynced" the moment the server confirms it.
            let pending = trips.filter { unsynced.contains($0.id) && !arrived.contains($0.id) }
            unsynced.subtract(arrived)

            trips = (remote + pending).sorted { $0.startDate > $1.startDate }
            state = .ready

            // After the trips, and never allowed to fail the sync: an
            // invitation that doesn't load costs you a card, not your trips.
            if includeInvitations {
                invitations = await SupabaseRepository.shared.loadInvitations()
            }

            if selectedTripID == nil || !trips.contains(where: { $0.id == selectedTripID }) {
                selectedTripID = currentTrip?.id ?? trips.first?.id
            }
        } catch {
            state = .failed(AuthService.message(for: error))
        }
    }

    /// Pull-to-refresh and "try again" both land here.
    func reload() async {
        await sync()
    }

    var selectedTrip: Trip? {
        guard let selectedTripID else { return trips.first }
        return trips.first { $0.id == selectedTripID } ?? trips.first
    }

    // MARK: - Portfolio totals

    /// Everything owed to you across trips, and everything you owe. Kept as
    /// two figures rather than one net, because "you're square" and "you're
    /// owed ₹9,150 and owe ₹9,150" are very different situations.
    var owedToYou: Double { trips.reduce(0) { $0 + $1.owedTo(Traveller.you.id) } }
    var youOwe: Double { trips.reduce(0) { $0 + $1.owing(Traveller.you.id) } }
    var netPosition: Double { owedToYou - youOwe }

    var activeTrips: [Trip] { trips.filter { $0.phase != .past } }

    /// Currency of the portfolio headline. Mixed-currency groups need real
    /// conversion; until then the most common code wins and we don't pretend.
    var primaryCurrency: String {
        let counts = Dictionary(grouping: trips, by: \.currencyCode).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "INR"
    }

    // MARK: - Mutation

    func add(_ trip: Trip) {
        trips.insert(trip, at: 0)
        auditor?.tripCreated(trip)
        selectedTripID = trip.id
        unsynced.insert(trip.id)

        Task {
            do {
                try await SupabaseRepository.shared.createTrip(trip)
                try await SupabaseRepository.shared.upsertItems(trip.items, tripID: trip.id)
                unsynced.remove(trip.id)
                writeFailure = nil

                // Only once it's actually saved. Telling four people they're on
                // a trip that then failed to write is worse than telling them
                // nothing.
                await SupabaseRepository.shared.announce(trip)
            } catch {
                writeFailure = "\(trip.title) didn't save. \(AuthService.message(for: error))"
            }
        }
    }

    /// Opens a trip's itinerary, replacing whatever was on the stack.
    func open(_ trip: Trip) {
        selectedTripID = trip.id
        itineraryPath = [.trip(trip.id)]
    }

    /// The one trip Home leads with: what's happening now, else what's next.
    var currentTrip: Trip? {
        trips.first { $0.phase == .live }
            ?? trips.filter { $0.phase == .upcoming }.min { $0.startDate < $1.startDate }
    }

    /// Deletes a trip for everybody on it.
    ///
    /// Removed from the list first so the screen answers immediately, and only
    /// put back if the server refuses — a delete that appears to work and then
    /// silently doesn't is worse than one that visibly fails, because the next
    /// sync resurrects a trip somebody believed they had got rid of.
    func delete(_ tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }

        let removed = trips[index]
        trips.remove(at: index)
        itineraryPath.removeAll { $0 == .trip(tripID) }
        if selectedTripID == tripID { selectedTripID = currentTrip?.id ?? trips.first?.id }

        notifier?.announceTripDeleted(removed)
        auditor?.tripDeleted(removed)

        Task {
            do {
                try await SupabaseRepository.shared.deleteTrip(tripID)
                writeFailure = nil
            } catch {
                trips.insert(removed, at: min(index, trips.count))
                writeFailure = "\(removed.title) couldn't be deleted. \(AuthService.message(for: error))"
            }
        }
    }

    /// Saves an edit to a trip's details and who organises it.
    ///
    /// Copies those fields onto the trip as it is *now*, rather than
    /// replacing it with what was passed in. Callers hand over an editor's
    /// draft, taken when the sheet opened: replacing the whole trip with it
    /// wound back every booking, settlement and member that had arrived since,
    /// and the old write then deleted those members on the server too. The
    /// roster isn't editable here at all — see `SupabaseRepository.updateTrip`.
    func update(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        let before = trips[index]

        var updated = before
        updated.title = trip.title
        updated.destination = trip.destination
        updated.startDate = trip.startDate
        updated.endDate = trip.endDate
        updated.currencyCode = trip.currencyCode
        updated.symbol = trip.symbol
        updated.tint = trip.tint
        updated.cover = trip.cover
        updated.titleStyle = trip.titleStyle
        // Only people actually on the trip can organise it.
        updated.organiserIDs = trip.organiserIDs.intersection(before.travellers.map(\.id))

        trips[index] = updated
        auditor?.tripUpdated(from: before, to: updated)
        write { try await SupabaseRepository.shared.updateTrip(updated, from: before) }
    }

    /// `notice`, when given, is what the group is told instead of the usual
    /// "Swastik changed …" — a change applied from an airline's email says
    /// the airline moved it, which is the fact the group needs.
    func updateItem(_ item: ItineraryItem, in tripID: UUID, notice: BookingNotice? = nil) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
              let itemIndex = trips[tripIndex].items.firstIndex(where: { $0.id == item.id })
        else { return }

        let before = trips[tripIndex].items[itemIndex]
        trips[tripIndex].items[itemIndex] = item

        // Announced from the *updated* trip: a payment notification quotes
        // each person's share, and the share is computed from the booking as
        // it now stands, not as it was a line ago.
        if let notice {
            notifier?.announce(notice, about: item.id, in: trips[tripIndex])
        } else {
            notifier?.announceBookingChanged(from: before, to: item, in: trips[tripIndex])
        }
        auditor?.expenseChanged(from: before, to: item, in: trips[tripIndex])

        write { try await SupabaseRepository.shared.upsertItem(item, tripID: tripID) }
    }

    /// Reports a payment as wrong — the only way a payment's status changes
    /// once it's recorded. There's no vote to lose to: whoever paid is taken
    /// at their word the moment they say so, and this is how anyone who
    /// disagrees says otherwise.
    func disputePayment(for itemID: UUID, in tripID: UUID, reason: String? = nil) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
              let itemIndex = trips[tripIndex].items.firstIndex(where: { $0.id == itemID })
        else { return }

        var item = trips[tripIndex].items[itemIndex]
        item.isDisputed = true
        item.disputedByID = Traveller.you.id
        item.disputedAt = Date()
        item.disputeReason = reason
        trips[tripIndex].items[itemIndex] = item

        notifier?.announceDispute(of: item, in: trips[tripIndex])
        auditor?.disputeRaised(on: item, reason: reason, in: trips[tripIndex])

        let captured = item
        write {
            try await SupabaseRepository.shared.disputePayment(
                itemID: captured.id,
                reason: reason,
                profileID: Traveller.you.id
            )
        }
    }

    /// Resolves an active payment dispute, updating the database and notifying travellers.
    func resolvePaymentDispute(for itemID: UUID, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
              let itemIndex = trips[tripIndex].items.firstIndex(where: { $0.id == itemID })
        else { return }

        var item = trips[tripIndex].items[itemIndex]
        item.isDisputed = false
        item.disputeResolvedAt = Date()
        item.disputeResolvedByID = Traveller.you.id
        trips[tripIndex].items[itemIndex] = item

        notifier?.announceDisputeResolved(for: item, in: trips[tripIndex])
        auditor?.disputeResolved(on: item, in: trips[tripIndex])

        let captured = item
        write {
            try await SupabaseRepository.shared.resolvePaymentDispute(
                itemID: captured.id,
                profileID: Traveller.you.id
            )
        }
    }

    func removeItem(_ itemID: UUID, in tripID: UUID, notice: BookingNotice? = nil) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
              let removed = trips[tripIndex].items.first(where: { $0.id == itemID })
        else { return }

        let before = trips[tripIndex]
        trips[tripIndex].items.removeAll { $0.id == itemID }
        if let notice {
            notifier?.announce(notice, about: nil, in: trips[tripIndex], removed: true)
        } else {
            notifier?.announceBookingRemoved(removed, from: trips[tripIndex])
        }
        auditor?.expenseRemoved(removed, from: before)

        write { try await SupabaseRepository.shared.deleteItem(itemID) }
    }

    /// Adds a booking, or replaces it if it's already here.
    ///
    /// Upsert rather than append because the callers save twice: the editor and
    /// quick add both write the booking straight away and then write it again a
    /// moment later with the category and glyph the model worked out. Appending
    /// blindly turned every classified booking into two.
    func addItem(_ item: ItineraryItem, to tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }

        if let existing = trips[tripIndex].items.firstIndex(where: { $0.id == item.id }) {
            let before = trips[tripIndex].items[existing]
            trips[tripIndex].items[existing] = item

            // The second of those two saves is the classifier's, not a
            // person's — it moves the category and the glyph and nothing else.
            // Auditing it would put "Category changed" under every booking a
            // second after "Added", which is noise in the one list that can
            // least afford it. A real edit reaches `updateItem`.
            if Self.isMaterialEdit(from: before, to: item) {
                auditor?.expenseChanged(from: before, to: item, in: trips[tripIndex])
            }

            write { try await SupabaseRepository.shared.upsertItem(item, tripID: tripID) }
            return
        }

        trips[tripIndex].items.append(item)
        // A booking outside the current span widens the trip rather than
        // falling off the end of the timeline.
        if item.day < trips[tripIndex].startDate { trips[tripIndex].startDate = item.day }
        if item.day > trips[tripIndex].endDate { trips[tripIndex].endDate = item.day }

        notifier?.announceBookingAdded(item, to: trips[tripIndex])
        auditor?.expenseAdded(item, to: trips[tripIndex])

        write { try await SupabaseRepository.shared.upsertItem(item, tripID: tripID) }
    }

    /// Whether a re-save of the same booking moved anything a person would
    /// recognise as a change, as opposed to something the app worked out for
    /// itself.
    private static func isMaterialEdit(from old: ItineraryItem, to new: ItineraryItem) -> Bool {
        old.cost != new.cost
            || old.split != new.split
            || old.customShares != new.customShares
            || old.participantIDs != new.participantIDs
            || old.paidByID != new.paidByID
            || old.paymentMethod != new.paymentMethod
            || old.receiptURL != new.receiptURL
            || old.title != new.title
            || old.vendor != new.vendor
            || old.date != new.date
            || old.time != new.time
    }

    /// Runs a write in the background and keeps whatever went wrong, so the
    /// screens can say so instead of the change quietly not existing.
    private func write(_ body: @escaping () async throws -> Void) {
        track {
            do {
                try await body()
                self.writeFailure = nil
            } catch {
                self.writeFailure = AuthService.message(for: error)
            }
        }
    }

    /// Runs work that handles its own failure — a settlement rolling itself
    /// back — where `settleWrites` can still wait for it. The settlement writes
    /// used to be bare tasks, so a Siri or watch "confirmed" was said before
    /// the server had answered, and stayed said when it then rolled back.
    private func track(_ body: @escaping () async -> Void) {
        let id = UUID()
        inFlight[id] = Task {
            await body()
            inFlight[id] = nil
        }
    }

    /// Writes handed to the server and not yet answered. See `settleWrites`.
    @ObservationIgnored private var inFlight: [UUID: Task<Void, Never>] = [:]

    /// Waits until every write already started has come back, then says what
    /// didn't make it — nil when everything did.
    ///
    /// The screens never wait: they show a change at once and put up
    /// `writeFailure` if the server bounces it. Siri can't work that way. It
    /// gets one chance to say "done", and nobody is looking at the app when a
    /// write fails a second later — so an intent clears the failure, makes its
    /// change, and settles before it answers.
    func settleWrites() async -> String? {
        while !inFlight.isEmpty {
            for task in Array(inFlight.values) { await task.value }
        }
        return writeFailure
    }

    func clearWriteFailure() { writeFailure = nil }

    func setCover(_ photo: TripPhoto, for tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        guard trips[index].cover == nil else { return }

        // Show the provider's URL straight away, then quietly swap in the
        // stored copy so every later appearance — and every other member of
        // the trip — reads the same file instead of re-searching.
        trips[index].cover = photo

        Task {
            let stored = await CoverStore.shared.persist(photo, for: tripID)
            guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
            trips[index].cover = stored
        }
    }

    /// A cover the user chose themselves always wins over a searched one.
    func setCustomCover(_ imageData: Data, for tripID: UUID) {
        Task {
            guard let stored = await CoverStore.shared.persist(imageData: imageData, for: tripID),
                  let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
            trips[index].cover = stored
            // Only this one, not `setCover`: that resolves a photo the app
            // went and found on its own, and a trail that logs the app's own
            // housekeeping alongside people's decisions buries the decisions.
            auditor?.coverChanged(in: trips[index])
        }
    }

    /// Finds a trip by its invite code, however it was typed or scanned.
    func trip(code: String) -> Trip? {
        let target = Trip.normaliseCode(code)
        guard !target.isEmpty else { return nil }
        return trips.first { Trip.normaliseCode($0.inviteCode) == target }
    }

    /// Finds a trip by invite code, on the server if it isn't already here.
    ///
    /// The local list can only ever contain trips you're *already* on, which
    /// is exactly the set you're not trying to join — so a local-only lookup
    /// could never find anybody else's trip. `trips_read` is open to any
    /// signed-in user precisely so this preview can work before membership.
    /// Server first, local only as an offline fallback. The server's copy is
    /// the authoritative one — it carries the current traveller list and
    /// bookings, where a local copy may be several edits behind — and asking
    /// it every time means the path that matters is the path that runs.
    func findTrip(code: String) async -> Trip? {
        if let remote = await SupabaseRepository.shared.trip(code: code) { return remote }
        return trip(code: code)
    }

    enum JoinOutcome: Equatable {
        case joined
        case alreadyMember
        case failed(String)
    }

    /// Joins a trip for real: writes the membership, then re-reads everything
    /// so the trip arrives with its people and bookings attached. `code` is
    /// the one the trip was found by — the server joins by code, not by id.
    func join(_ tripID: UUID, code: String) async -> JoinOutcome {
        do {
            let isNew = try await SupabaseRepository.shared.join(code: code)
            await sync()
            if isNew, let joined = trip(tripID) {
                auditor?.memberJoined(joined, travellerCount: joined.travellers.count)
            }
            return isNew ? .joined : .alreadyMember
        } catch {
            return .failed(AuthService.message(for: error))
        }
    }

    func trip(_ id: UUID?) -> Trip? {
        guard let id else { return nil }
        return trips.first { $0.id == id }
    }

    // MARK: - Settlements

    /// Every settlement across every trip where you're the one being asked to
    /// agree. What the Home pending-action card and the Settle tab's "Waiting
    /// on you" both read from.
    var settlementsAwaitingYou: [(trip: Trip, settlement: Settlement)] {
        trips.flatMap { trip in
            trip.pendingSettlements.filter(\.youAreRecipient).map { (trip, $0) }
        }
        .sorted { $0.settlement.createdAt > $1.settlement.createdAt }
    }

    /// Records "I paid this" and asks the recipient to agree. Optimistic, like
    /// every other write here: it's on screen — as a pending claim, correctly
    /// unable to move anyone's balance yet — before the network answers.
    func createSettlement(
        tripID: UUID,
        toID: UUID,
        amount: Double,
        method: PaymentMethod,
        proofURL: URL?,
        note: String
    ) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }

        let settlement = Settlement(
            tripID: tripID,
            fromID: Traveller.you.id,
            toID: toID,
            amount: amount,
            currencyCode: trips[tripIndex].currencyCode,
            method: method,
            proofURL: proofURL,
            note: note
        )
        trips[tripIndex].settlements.append(settlement)
        auditor?.settlementRequested(settlement, in: trips[tripIndex])

        let trip = trips[tripIndex]
        let payer = Traveller.you.name
        let each = Money.format(amount, code: trip.currencyCode)

        track { [self] in
            do {
                try await SupabaseRepository.shared.createSettlement(settlement)
                writeFailure = nil
            } catch {
                // The claim stays on screen rather than vanishing — a request
                // that silently disappears reads as "it went through", which
                // is the one thing worse than a visible failure here.
                writeFailure = "Couldn't send that to \(trip.traveller(toID)?.name ?? "them"). \(AuthService.message(for: error))"
                return
            }

            notifier?.post(
                AppNotification(
                    kind: .settlementRequested,
                    title: "\(payer) says they paid you \(each)",
                    body: "\(trip.title) · \(method.label)\(note.isEmpty ? "" : " · \(note)")",
                    tripID: tripID,
                    settlementID: settlement.id
                ),
                to: [toID]
            )
        }
    }

    /// The recipient's answer — confirm it happened, or say it didn't.
    func respondToSettlement(_ settlement: Settlement, with status: Settlement.Status, in tripID: UUID) {
        guard status != .pending,
              let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
              let settlementIndex = trips[tripIndex].settlements.firstIndex(where: { $0.id == settlement.id })
        else { return }

        trips[tripIndex].settlements[settlementIndex].status = status
        trips[tripIndex].settlements[settlementIndex].respondedByID = Traveller.you.id
        trips[tripIndex].settlements[settlementIndex].respondedAt = Date()

        let trip = trips[tripIndex]
        let responder = Traveller.you.name
        let each = Money.format(settlement.amount, code: settlement.currencyCode)

        track { [self] in
            do {
                try await SupabaseRepository.shared.respondToSettlement(
                    settlement.id, status: status, respondedBy: Traveller.you.id
                )
                writeFailure = nil
            } catch {
                // Roll the local state back — an answer that didn't actually
                // save has to stop looking answered.
                if let index = trips.firstIndex(where: { $0.id == tripID }),
                   let sIndex = trips[index].settlements.firstIndex(where: { $0.id == settlement.id }) {
                    trips[index].settlements[sIndex].status = .pending
                    trips[index].settlements[sIndex].respondedByID = nil
                    trips[index].settlements[sIndex].respondedAt = nil
                }
                writeFailure = "Couldn't send that answer. \(AuthService.message(for: error))"
                return
            }

            // Only once it saved. An answer that rolled back is not something
            // that happened, and a trail claiming otherwise is worse than one
            // that missed it.
            auditor?.settlementAnswered(settlement, with: status, in: trip)

            notifier?.post(
                AppNotification(
                    kind: status == .confirmed ? .settlementConfirmed : .settlementDeclined,
                    title: status == .confirmed
                        ? "\(responder) confirmed your \(each) payment"
                        : "\(responder) says they haven't received \(each)",
                    body: status == .confirmed
                        ? "\(trip.title) · that balance is settled."
                        : "\(trip.title) · worth checking the method and trying again.",
                    tripID: tripID,
                    settlementID: settlement.id
                ),
                to: [settlement.fromID]
            )
        }
    }

    /// Pulls back a claim before the other side has answered it.
    func withdrawSettlement(_ settlement: Settlement, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }
        let trip = trips[tripIndex]
        trips[tripIndex].settlements.removeAll { $0.id == settlement.id }

        track { [self] in
            do {
                try await SupabaseRepository.shared.withdrawSettlement(settlement.id)
                auditor?.settlementWithdrawn(settlement, in: trip)
                writeFailure = nil
            } catch {
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index].settlements.append(settlement)
                }
                writeFailure = "Couldn't withdraw that. \(AuthService.message(for: error))"
            }
        }
    }

    // MARK: - Invitations

    /// Trips you've been asked to join and haven't answered. Home leads with
    /// these — an invitation outranks everything else on the screen, because
    /// until it's answered you aren't on the trip it's about.
    private(set) var invitations: [TripInvitation] = []

    /// Asks somebody to join, rather than putting them on the trip.
    ///
    /// The traveller lands on the roster straight away so the organiser can
    /// see who they've asked, but `invitedIDs` keeps them out of every share
    /// calculation until they accept — see `Trip.bearers(of:)`. Nobody's
    /// figures move on an invitation, which is the entire reason this isn't
    /// just an append.
    func invite(_ traveller: Traveller, to tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        guard !trips[index].travellers.contains(where: { $0.id == traveller.id }) else { return }

        let previous = trips[index]
        trips[index].travellers.append(traveller)
        trips[index].invitedIDs.insert(traveller.id)

        let trip = trips[index]

        Task {
            do {
                try await SupabaseRepository.shared.invite(traveller, to: tripID)
                writeFailure = nil
            } catch {
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index] = previous
                }
                writeFailure = "Couldn't invite \(traveller.name). \(AuthService.message(for: error))"
                return
            }

            notifier?.announceInvitation(of: traveller, to: trip)
            auditor?.memberInvited(traveller, to: trip)
        }
    }

    /// Withdraws an invitation nobody has answered yet.
    func cancelInvitation(of travellerID: UUID, in tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }),
              trips[index].invitedIDs.contains(travellerID)
        else { return }

        let previous = trips[index]
        let traveller = trips[index].traveller(travellerID)
        trips[index].travellers.removeAll { $0.id == travellerID }
        trips[index].invitedIDs.remove(travellerID)

        Task {
            do {
                try await SupabaseRepository.shared.withdrawInvitation(of: travellerID, tripID: tripID)
                if let traveller { auditor?.invitationCancelled(of: traveller, in: previous) }
                writeFailure = nil
            } catch {
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index] = previous
                }
                writeFailure = "Couldn't withdraw that invitation. \(AuthService.message(for: error))"
            }
        }
    }

    /// Your answer to an invitation.
    ///
    /// Accepting re-syncs rather than patching local state: the trip you get
    /// as a member is a completely different object from the preview you were
    /// shown — it has the itinerary, the ledger and the chat attached — so
    /// there's nothing sensible to merge, and the server is the thing that
    /// decides what you can now see.
    func respondToInvitation(_ invitation: TripInvitation, accept: Bool) async -> Bool {
        invitations.removeAll { $0.id == invitation.id }

        do {
            if accept {
                try await SupabaseRepository.shared.acceptInvitation(tripID: invitation.trip.id)
                await sync()
                selectedTripID = invitation.trip.id
                if let joined = trip(invitation.trip.id) {
                    auditor?.memberJoined(joined, travellerCount: joined.travellers.count)
                }
            } else {
                try await SupabaseRepository.shared.declineInvitation(tripID: invitation.trip.id)
            }
            writeFailure = nil
            return true
        } catch {
            invitations.insert(invitation, at: 0)
            writeFailure = accept
                ? "Couldn't join \(invitation.trip.title). \(AuthService.message(for: error))"
                : "Couldn't decline that. \(AuthService.message(for: error))"
            return false
        }
    }

    // MARK: - Departures

    /// Every departure across every trip that's waiting on you to answer it.
    /// The mirror of `settlementsAwaitingYou`, and it feeds the same places.
    var departuresAwaitingYou: [(trip: Trip, departure: TripDeparture)] {
        trips.flatMap { trip in
            guard trip.youAreOrganiser else { return [(trip: Trip, departure: TripDeparture)]() }
            return trip.pendingDepartures
                .filter { $0.travellerID != Traveller.you.id }
                .map { (trip, $0) }
        }
        .sorted { $0.departure.proposedAt > $1.departure.proposedAt }
    }

    /// Puts a departure to the group. Changes nothing about anybody's balance
    /// — `Trip.bearers(of:)` only honours a `.confirmed` record — which is the
    /// whole reason this is a two-step and not a button.
    func proposeDeparture(_ plan: DeparturePlan) {
        guard let index = trips.firstIndex(where: { $0.id == plan.trip.id }) else { return }

        let departure = plan.record(status: .pending)
        trips[index].departures.removeAll { $0.travellerID == departure.travellerID }
        trips[index].departures.append(departure)

        notifier?.announceDepartureRequest(plan, in: trips[index])
        if let leaver = trips[index].traveller(departure.travellerID) {
            auditor?.departureProposed(departure, of: leaver, in: trips[index])
        }

        write { try await SupabaseRepository.shared.upsertDeparture(departure) }
    }

    /// The group's answer.
    ///
    /// Confirming is the only place a departure touches the itinerary, and it
    /// touches it in exactly one way: an unpaid, per-head booking the leaver
    /// dropped genuinely costs less now, so its price comes down. Everything
    /// else — who bears what — is derived from the record rather than written
    /// into the bookings, so it stays reversible and stays auditable.
    func respondToDeparture(
        _ departure: TripDeparture,
        with status: TripDeparture.Status,
        in tripID: UUID
    ) {
        guard status != .pending,
              let index = trips.firstIndex(where: { $0.id == tripID }),
              let slot = trips[index].departures.firstIndex(where: { $0.id == departure.id }),
              let traveller = trips[index].traveller(departure.travellerID)
        else { return }

        let previous = trips[index]

        if status == .confirmed, let plan = DeparturePlan.review(departure, in: previous) {
            // Only the bookings that actually moved, so a confirmation doesn't
            // rewrite forty rows to change three.
            let repriced = plan.adjustedItems.filter { updated in
                previous.items.first { $0.id == updated.id }?.cost != updated.cost
            }
            trips[index].items = plan.adjustedItems

            for item in repriced {
                // The previous price is read from `previous`, which still holds
                // the trip as it was before the plan was applied — this is the
                // one change in the app that moves money without anybody
                // typing a figure, so the trail has to be able to show both
                // sides of it.
                if let was = previous.items.first(where: { $0.id == item.id })?.cost {
                    auditor?.repriced(item, from: was, by: traveller.name, in: previous)
                }
                write { try await SupabaseRepository.shared.upsertItem(item, tripID: tripID) }
            }
        }

        trips[index].departures[slot].status = status
        trips[index].departures[slot].respondedByID = Traveller.you.id
        trips[index].departures[slot].respondedAt = Date()
        // The figure both sides just agreed to, kept as agreed rather than
        // recomputed later — see `TripDeparture.agreedAmounts`.
        if status == .confirmed,
           let plan = DeparturePlan.review(trips[index].departures[slot], in: previous) {
            trips[index].departures[slot].agreedBalance = plan.finalBalance
            trips[index].departures[slot].agreedAmounts = plan
                .lines
                .filter(\.isBorne)
                .reduce(into: [:]) { $0[$1.item.id] = $1.amount }
        }

        let stored = trips[index].departures[slot]

        if status == .confirmed {
            notifier?.announceDeparture(stored, of: traveller, in: trips[index])
        }

        let answered = trips[index]

        Task {
            do {
                try await SupabaseRepository.shared.upsertDeparture(stored)
                auditor?.departureAnswered(stored, of: traveller, with: status, in: answered)
                writeFailure = nil
            } catch {
                // Put it back the way it was. A departure that looks answered
                // and silently isn't leaves two people with different ideas
                // about who owes what, which is the failure this whole feature
                // exists to prevent.
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index] = previous
                }
                writeFailure = "Couldn't save that answer. \(AuthService.message(for: error))"
            }
        }
    }

    /// Pulls back a proposal before it's been answered.
    func withdrawDeparture(_ departure: TripDeparture, in tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        if let leaver = trips[index].traveller(departure.travellerID) {
            auditor?.departureWithdrawn(departure, of: leaver, in: trips[index])
        }
        trips[index].departures.removeAll { $0.id == departure.id }

        Task {
            do {
                try await SupabaseRepository.shared.deleteDeparture(departure.id)
                writeFailure = nil
            } catch {
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index].departures.append(departure)
                }
                writeFailure = "Couldn't withdraw that. \(AuthService.message(for: error))"
            }
        }
    }

    // MARK: - Settlement realtime

    /// Subscribes to every change on `public.settlements`. Row-level security
    /// already narrows what a client can select to trips you're a member of,
    /// so this doesn't filter by trip — it merges everything it's allowed to
    /// see and only surfaces a toast for the rows that are actually about you.
    func startSettlementRealtime() async {
        guard settlementChannel == nil else { return }

        let channel = client.channel("settlements:live")
        settlementChannel = channel

        let inserts = channel.postgresChange(InsertAction.self, schema: "public", table: "settlements")
        let updates = channel.postgresChange(UpdateAction.self, schema: "public", table: "settlements")

        do {
            try await channel.subscribeWithError()
        } catch {
            settlementChannel = nil
            return
        }

        settlementTasks.append(Task { [weak self] in
            for await insert in inserts {
                guard let self else { return }
                guard let row = try? insert.decodeRecord(as: SettlementRow.self, decoder: Self.decoder) else { continue }
                await self.mergeRealtime(row.asSettlement)
            }
        })

        settlementTasks.append(Task { [weak self] in
            for await update in updates {
                guard let self else { return }
                guard let row = try? update.decodeRecord(as: SettlementRow.self, decoder: Self.decoder) else { continue }
                await self.mergeRealtime(row.asSettlement)
            }
        })
    }

    func stopSettlementRealtime() {
        settlementTasks.forEach { $0.cancel() }
        settlementTasks.removeAll()

        let channel = settlementChannel
        settlementChannel = nil
        Task { await channel?.unsubscribe() }
    }

    /// Folds one row from the wire into local state, and — only when the row
    /// is both new-to-this-device and about *you* — surfaces it.
    ///
    /// The two writes above already append/mutate optimistically on the
    /// device that made them, so the echo of your own insert or your own
    /// response arrives here and matches what's already on screen exactly —
    /// `existing == row` — and is skipped. What's left after that filter is,
    /// by construction, something that happened somewhere else.
    private func mergeRealtime(_ settlement: Settlement) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == settlement.tripID }) else { return }

        let existingIndex = trips[tripIndex].settlements.firstIndex { $0.id == settlement.id }
        let existing = existingIndex.map { trips[tripIndex].settlements[$0] }
        guard existing != settlement else { return }

        if let existingIndex {
            trips[tripIndex].settlements[existingIndex] = settlement
        } else {
            trips[tripIndex].settlements.append(settlement)
        }

        let trip = trips[tripIndex]
        let payerName = trip.traveller(settlement.fromID)?.name ?? "Someone"
        let each = Money.format(settlement.amount, code: settlement.currencyCode)

        // A brand-new pending row addressed to you: something to answer.
        if existing == nil, settlement.status == .pending, settlement.toID == Traveller.you.id {
            toaster?.show(.init(
                kind: .requested,
                title: "\(payerName) says they paid you \(each)",
                subtitle: "\(trip.title) · tap to review",
                settlement: settlement
            ))
            return
        }

        // A pending claim you raised just got answered.
        if let existing, existing.status == .pending, settlement.status != .pending, settlement.fromID == Traveller.you.id {
            let recipient = trip.traveller(settlement.toID)?.name ?? "They"
            toaster?.show(.init(
                kind: settlement.status == .confirmed ? .confirmed : .declined,
                title: settlement.status == .confirmed
                    ? "\(recipient) confirmed your payment"
                    : "\(recipient) says they didn't get it",
                subtitle: settlement.status == .confirmed
                    ? "\(each) · \(trip.title) is settled up"
                    : "\(each) · \(trip.title) · try again with them",
                settlement: settlement
            ))
        }
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter.supabase.date(from: text) { return date }
            if let date = ISO8601DateFormatter.supabaseFractional.date(from: text) { return date }
            return Date()
        }
        return decoder
    }()
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var tripStore = TripStore()
}
