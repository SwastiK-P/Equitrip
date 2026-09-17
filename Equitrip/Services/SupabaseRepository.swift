//
//  SupabaseRepository.swift
//  Equitrip
//

import SwiftUI
import Supabase

/// Everything that talks to Postgres.
///
/// Postgres is the only source of truth. There is deliberately no local
/// sample-data fallback: one used to sit behind this and it did real damage —
/// the fakes were rebuilt with fresh UUIDs on every launch, so anything that
/// wrote through them (chat, most visibly) uploaded a brand-new throwaway trip
/// each cold start and could never read its own history back. A failure here
/// now surfaces as a failure, and the screens say so.
@MainActor
final class SupabaseRepository {
    static let shared = SupabaseRepository()

    private var client: SupabaseClient { AuthService.shared.client }

    /// The signed-in user's row in `profiles`.
    ///
    /// Cached against the `auth.users` id it was resolved for, and only
    /// returned when the two still agree. Caching it on its own was a serious
    /// bug: this is a process-wide singleton, so signing out and signing in as
    /// somebody else handed the second account the first account's profile id.
    /// From there everything downstream was wrong in a way that looked
    /// plausible — the new user loaded the old user's trips, showed up as
    /// their organiser, saw themselves as the only traveller (their own name
    /// painted over the old profile's row), and couldn't join the trip because
    /// as far as the server was concerned they already had.
    private var profileID: UUID?

    /// Which `auth.users` id `profileID` belongs to. The pair is what makes
    /// the cache safe; either alone is not.
    private var profileOwner: UUID?

    /// The face on the signed-in user's profile row, as the server has it.
    /// Read once while resolving the profile rather than fetched separately,
    /// because every screen wants it and none of them should have to ask.
    private(set) var currentAvatar: (asset: String, url: URL?)?

    /// The resolved profile id, if one has been resolved for the current
    /// session. Read-only and non-throwing, for callers that only want to know
    /// whether we have one yet.
    var currentProfileID: UUID? {
        guard let profileOwner, profileOwner == AuthService.shared.session?.user.id else { return nil }
        return profileID
    }

    /// Drops the cached identity. Called on sign-out, and on any sign-in, so
    /// nothing from the previous account can outlive it.
    func forgetProfile() {
        profileID = nil
        profileOwner = nil
        currentAvatar = nil
    }

    enum RepositoryError: LocalizedError {
        case notSignedIn
        case schemaMissing

        var errorDescription: String? {
            switch self {
            case .notSignedIn: "You're not signed in."
            case .schemaMissing: "The database schema hasn't been created yet."
            }
        }
    }

    // MARK: - Profile

    /// Finds (or creates) the profile row for the signed-in account.
    ///
    /// A trigger makes one on signup, but accounts that predate the migration
    /// won't have it — so this backfills rather than failing.
    @discardableResult
    func resolveProfile() async throws -> UUID {
        guard let user = AuthService.shared.session?.user else {
            forgetProfile()
            throw RepositoryError.notSignedIn
        }

        // The owner check, not the presence of a value, is what makes this a
        // cache rather than a leak between accounts.
        if let profileID, profileOwner == user.id { return profileID }
        forgetProfile()

        let existing: [ProfileRow] = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: user.id)
            .limit(1)
            .execute()
            .value

        if let row = existing.first {
            profileID = row.id
            profileOwner = user.id
            currentAvatar = (row.avatar_asset, row.avatar_url.flatMap(URL.init(string:)))
            CurrentUser.adoptUPI(row.upi_id)
            return row.id
        }

        let name: String = {
            if case let .string(value)? = user.userMetadata["full_name"], !value.isEmpty { return value }
            return user.email?.components(separatedBy: "@").first ?? "Traveller"
        }()

        let inserted: ProfileRow = try await client
            .from("profiles")
            .insert(["user_id": AnyJSON.string(user.id.uuidString), "display_name": .string(name)])
            .select()
            .single()
            .execute()
            .value

        profileID = inserted.id
        profileOwner = user.id
        currentAvatar = (inserted.avatar_asset, inserted.avatar_url.flatMap(URL.init(string:)))
        return inserted.id
    }

    /// Saves the face the signed-in user picked for themselves.
    ///
    /// Both fields go every time: choosing an avatar has to clear a
    /// photograph that was there before it, or the photo would keep winning
    /// and the pick would look like it did nothing.
    func updateAvatar(asset: String, url: URL?) async throws {
        let profile = try await resolveProfile()
        currentAvatar = (asset, url)

        try await client
            .from("profiles")
            .update([
                "avatar_asset": AnyJSON.string(asset),
                "avatar_url": url.map { AnyJSON.string($0.absoluteString) } ?? .null
            ])
            .eq("id", value: profile)
            .execute()
    }

    /// Saves the VPA the signed-in user pays into, so people settling up with
    /// them can see it rather than being asked to type it in on their behalf.
    /// An empty string clears it back to "not set".
    func updateUPIID(_ vpa: String) async throws {
        let profile = try await resolveProfile()
        let trimmed = vpa.trimmingCharacters(in: .whitespaces)
        CurrentUser.adoptUPI(trimmed)

        try await client
            .from("profiles")
            .update(["upi_id": trimmed.isEmpty ? .null : AnyJSON.string(trimmed)])
            .eq("id", value: profile)
            .execute()
    }

    // MARK: - Trips

    /// Loads every trip the signed-in user is a member of, with its people and
    /// bookings.
    ///
    /// Throws rather than returning nil. An empty array means "you're on no
    /// trips", which is a real and perfectly normal state; a thrown error means
    /// the server couldn't be reached or the schema isn't there. Those two used
    /// to be indistinguishable, and collapsing them is what let a broken
    /// connection masquerade as a populated app.
    func loadTrips() async throws -> [Trip] {
        let profile = try await resolveProfile()

        // Accepted memberships only. An outstanding invitation is a row here
        // too, but the trip behind it is deliberately unreadable until it's
        // accepted — `loadInvitations` fetches the little that *is* readable.
        let memberships: [MembershipRow] = try await client
            .from("trip_members")
            .select("trip_id")
            .eq("profile_id", value: profile)
            .eq("status", value: "active")
            .execute()
            .value

        let tripIDs = memberships.map(\.trip_id)
        guard !tripIDs.isEmpty else { return [] }

        async let tripRows: [TripRow] = client
            .from("trips").select().in("id", values: tripIDs).execute().value
        async let memberRows: [TripMemberRow] = client
            .from("trip_members").select().in("trip_id", values: tripIDs).execute().value
        async let profileRows: [ProfileRow] = client
            .from("profiles").select().execute().value
        async let itemRows: [ItemRow] = client
            .from("itinerary_items").select().in("trip_id", values: tripIDs).execute().value
        // Kicked off alongside the rest, but awaited separately below with
        // `try?` — `settlements` is the newest table, and a project that
        // hasn't run its migration yet shouldn't lose every trip over it.
        async let settlementRows: [SettlementRow] = client
            .from("settlements").select().in("trip_id", values: tripIDs).execute().value
        // Same treatment, same reason — a project that hasn't run the
        // departures migration should load its trips, not fail all of them.
        async let departureRows: [DepartureRow] = client
            .from("trip_departures").select().in("trip_id", values: tripIDs).execute().value

        let (trips, members, profiles, items) = try await (tripRows, memberRows, profileRows, itemRows)
        let settlements = (try? await settlementRows) ?? []
        let departures = (try? await departureRows) ?? []

        let itemIDs = items.map(\.id)
        let participantRows: [ParticipantRow] = itemIDs.isEmpty ? [] : (try await client
            .from("item_participants").select().in("item_id", values: itemIDs).execute().value)

        return assemble(
            trips: trips,
            members: members,
            profiles: profiles,
            items: items,
            participants: participantRows,
            settlements: settlements,
            departures: departures,
            me: profile
        )
    }

    /// Rebuilds the object graph the UI works in from seven flat tables.
    private func assemble(
        trips: [TripRow],
        members: [TripMemberRow],
        profiles: [ProfileRow],
        items: [ItemRow],
        participants: [ParticipantRow],
        settlements: [SettlementRow],
        departures: [DepartureRow] = [],
        me: UUID
    ) -> [Trip] {
        let travellerByID = Dictionary(
            uniqueKeysWithValues: profiles.map { ($0.id, $0.asTraveller(currentProfile: me)) }
        )
        let membersByTrip = Dictionary(grouping: members, by: \.trip_id)
        let itemsByTrip = Dictionary(grouping: items, by: \.trip_id)
        let participantsByItem = Dictionary(grouping: participants, by: \.item_id)
        let settlementsByTrip = Dictionary(grouping: settlements, by: \.trip_id)
        let departuresByTrip = Dictionary(grouping: departures, by: \.trip_id)

        return trips.map { row in
            let tripMembers = membersByTrip[row.id] ?? []
            let travellers = tripMembers.compactMap { travellerByID[$0.profile_id] }

            let bookings = (itemsByTrip[row.id] ?? []).map { item in
                let rows = participantsByItem[item.id] ?? []
                return item.asItineraryItem(
                    participantIDs: Set(rows.map(\.profile_id)),
                    // Only rows that actually carry a figure. A null `amount`
                    // is the ordinary case — it means "this person is on the
                    // booking", not "this person owes nothing".
                    customShares: rows.reduce(into: [:]) { store, row in
                        if let amount = row.amount { store[row.profile_id] = amount }
                    }
                )
            }

            return row.asTrip(
                travellers: travellers,
                organiserIDs: Set(tripMembers.filter { $0.role == "organiser" }.map(\.profile_id)),
                invitedIDs: Set(tripMembers.filter(\.isInvited).map(\.profile_id)),
                items: bookings,
                settlements: (settlementsByTrip[row.id] ?? []).map(\.asSettlement),
                departures: (departuresByTrip[row.id] ?? []).map(\.asDeparture)
            )
        }
    }

    // MARK: - Writes

    /// Writes a trip and its membership.
    ///
    /// Throws. Every one of these used to be a `try?`, which meant a trip that
    /// failed to save looked exactly like one that saved — right up until the
    /// next sync replaced it with the server's version of reality, in which it
    /// had never existed. A write that fails has to say so.
    func upsertTrip(_ trip: Trip) async throws {
        let profile = try await resolveProfile()

        // A traveller added by hand — an invitee typed into the picker — has
        // no `profiles` row of their own. Without this, `trip_members` and
        // later `messages` inserts fail their foreign key against someone who,
        // as far as the server knows, doesn't exist.
        try await ensureProfiles(for: trip.travellers, excluding: profile)

        try await client.from("trips").upsert(TripRow(trip: trip, createdBy: profile)).execute()

        let members = trip.travellers.map {
            TripMemberWrite(
                trip_id: trip.id,
                profile_id: $0.id,
                role: trip.organiserIDs.contains($0.id) ? "organiser" : "traveller"
            )
        }
        try await client.from("trip_members").upsert(members).execute()

        // Everyone who is no longer on the trip. An upsert only ever adds and
        // updates, so without this a traveller taken off the trip stays in
        // `trip_members` — removed on the screen, still there in the table,
        // and back again the moment the next sync reads membership from the
        // server. Nobody trusts a removal that undoes itself.
        //
        // Guarded on a non-empty roster: `not.in.()` is not a filter the
        // server would accept, and a trip with no members is a bug elsewhere
        // rather than an instruction to empty the table.
        guard !members.isEmpty else { return }
        let keep = members.map(\.profile_id.uuidString).joined(separator: ",")
        try await client
            .from("trip_members")
            .delete()
            .eq("trip_id", value: trip.id)
            .not("profile_id", operator: .in, value: "(\(keep))")
            .execute()
    }

    /// Backfills a `profiles` row for every traveller that doesn't have one.
    /// `ignoreDuplicates` so this never clobbers a real account's row — the
    /// signed-in user's own profile (passed as `excluding`) is skipped
    /// entirely, and everyone else only gets inserted if they're missing.
    private func ensureProfiles(for travellers: [Traveller], excluding: UUID) async throws {
        // Anyone added by email already has a row — `invite_traveller` made it,
        // and its display name is theirs. Only a traveller from somewhere else
        // needs backfilling, and even then `ignoreDuplicates` keeps this from
        // ever writing over a real account's name.
        let rows = travellers
            .filter { $0.id != excluding && $0.email == nil }
            .map { ProfileRow(id: $0.id, user_id: nil, display_name: $0.name, avatar_asset: $0.asset) }
        guard !rows.isEmpty else { return }

        try await client.from("profiles").upsert(rows, ignoreDuplicates: true).execute()
    }

    /// Writes a whole itinerary at once.
    ///
    /// Saving an imported trip used to be one round trip per booking, and a
    /// forty-five-booking PDF is ninety requests fired one after another. The
    /// first one to fail took every booking after it with it, which is how a
    /// trip imported as forty-five came back from the server as thirty-one —
    /// the write had stopped a third of the way through and the only trace was
    /// a banner nobody reads. Three requests can't half-succeed like that.
    func upsertItems(_ items: [ItineraryItem], tripID: UUID) async throws {
        guard !items.isEmpty else { return }

        try await client
            .from("itinerary_items")
            .upsert(items.map { ItemRow(item: $0, tripID: tripID) })
            .execute()

        try await client
            .from("item_participants")
            .delete()
            .in("item_id", values: items.map(\.id))
            .execute()

        let participants = items.flatMap { item in
            item.participantIDs.map { ParticipantRow(item: item, profileID: $0) }
        }
        guard !participants.isEmpty else { return }

        try await client.from("item_participants").insert(participants).execute()
    }

    func upsertItem(_ item: ItineraryItem, tripID: UUID) async throws {
        try await client.from("itinerary_items").upsert(ItemRow(item: item, tripID: tripID)).execute()
        try await client.from("item_participants").delete().eq("item_id", value: item.id).execute()

        guard !item.participantIDs.isEmpty else { return }
        let rows = item.participantIDs.map { ParticipantRow(item: item, profileID: $0) }
        try await client.from("item_participants").insert(rows).execute()
    }

    func deleteItem(_ itemID: UUID) async throws {
        try await client.from("itinerary_items").delete().eq("id", value: itemID).execute()
    }

    /// Disputing a payment flags the booking so all trip members see it.
    func disputePayment(itemID: UUID, reason: String?, profileID: UUID) async throws {
        try await client
            .from("itinerary_items")
            .update([
                "is_disputed": AnyJSON.bool(true),
                "disputed_by": AnyJSON.string(profileID.uuidString),
                "disputed_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
                "dispute_reason": reason.map { AnyJSON.string($0) } ?? .string("")
            ])
            .eq("id", value: itemID)
            .execute()
    }

    /// Resolves an open dispute on a booking's payment.
    func resolvePaymentDispute(itemID: UUID, profileID: UUID) async throws {
        try await client
            .from("itinerary_items")
            .update([
                "is_disputed": AnyJSON.bool(false),
                "dispute_resolved_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
                "dispute_resolved_by": AnyJSON.string(profileID.uuidString)
            ])
            .eq("id", value: itemID)
            .execute()
    }

    /// Removes a trip outright.
    ///
    /// The bookings, membership, messages and participant rows all hang off
    /// `trips` with `on delete cascade`, so this one statement takes the whole
    /// graph with it. Deliberately not a "leave the trip" — that's a different
    /// act with a different meaning, and conflating them is how somebody
    /// stepping away from a holiday deletes everyone else's ledger.
    func deleteTrip(_ tripID: UUID) async throws {
        try await client.from("trips").delete().eq("id", value: tripID).execute()
    }

    /// Looks a trip up by invite code without needing membership — this is the
    /// join preview, shown to someone who isn't on the trip yet.
    func trip(code: String) async -> Trip? {
        let normalised = Trip.normaliseCode(code)
        guard !normalised.isEmpty else { return nil }

        do {
            let rows: [TripRow] = try await client
                .from("trips").select().eq("invite_code", value: normalised).limit(1).execute().value
            guard let row = rows.first else { return nil }

            let members: [TripMemberRow] = try await client
                .from("trip_members").select().eq("trip_id", value: row.id).execute().value
            let profiles: [ProfileRow] = try await client.from("profiles").select().execute().value
            // Not `from("itinerary_items")`: that read is scoped to trip
            // members by RLS, and the whole point of this screen is that the
            // person looking isn't one yet. It came back empty every time, so
            // a fully-planned trip previewed as "0 bookings · ₹0". The RPC
            // hands over the two aggregates and nothing else.
            let summary: [TripPreviewRow]? = try? await client
                .rpc("trip_preview", params: ["p_code": normalised])
                .execute()
                .value

            let me = currentProfileID ?? UUID()
            let byID = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.asTraveller(currentProfile: me)) })

            var trip = row.asTrip(
                travellers: members.compactMap { byID[$0.profile_id] },
                organiserIDs: Set(members.filter { $0.role == "organiser" }.map(\.profile_id)),
                items: []
            )

            if let preview = summary?.first {
                trip.previewBookingCount = preview.booking_count
                trip.previewCost = preview.total_cost
            }
            return trip
        } catch {
            return nil
        }
    }

    /// Adds the signed-in user to a trip. Returns false when they were
    /// already on it.
    ///
    /// Checks membership first rather than relying on the upsert's conflict
    /// clause, because that clause is an UPDATE — re-joining a trip you
    /// organise would quietly demote you to 'traveller'. `ignoreDuplicates`
    /// backs that up against the race between the check and the write.
    @discardableResult
    func join(tripID: UUID) async throws -> Bool {
        let profile = try await resolveProfile()

        let existing: [TripMemberRow] = try await client
            .from("trip_members")
            .select()
            .eq("trip_id", value: tripID)
            .eq("profile_id", value: profile)
            .limit(1)
            .execute()
            .value

        guard existing.isEmpty else { return false }

        try await client
            .from("trip_members")
            .upsert(
                TripMemberWrite(trip_id: tripID, profile_id: profile, role: "traveller"),
                ignoreDuplicates: true
            )
            .execute()

        return true
    }

    func setCover(_ url: String, tripID: UUID) async {
        _ = try? await client.from("trips").update(["cover_url": url]).eq("id", value: tripID).execute()
    }

    // MARK: - Settlements

    /// Records "I paid this". Always starts `pending` — `settlements_insert`
    /// wouldn't let it start any other way even if this tried to.
    func createSettlement(_ settlement: Settlement) async throws {
        try await client.from("settlements").insert(SettlementRow(settlement: settlement)).execute()
    }

    /// The recipient's answer. `settlements_respond` only lets this touch a
    /// row where `to_profile` is the caller and it's still pending, so an
    /// attempt to answer somebody else's claim fails at the database rather
    /// than quietly succeeding on a device that shouldn't be able to.
    func respondToSettlement(_ id: UUID, status: Settlement.Status, respondedBy: UUID) async throws {
        try await client
            .from("settlements")
            .update([
                "status": AnyJSON.string(status.rawValue),
                "responded_by": .string(respondedBy.uuidString),
                "responded_at": .string(ISO8601DateFormatter.supabaseFractional.string(from: Date()))
            ])
            .eq("id", value: id)
            .execute()
    }

    /// Pulls back a claim before anyone has answered it — mis-picked the
    /// wrong person, fat-fingered the amount. `settlements_withdraw` refuses
    /// this once the row is no longer pending.
    func withdrawSettlement(_ id: UUID) async throws {
        try await client.from("settlements").delete().eq("id", value: id).execute()
    }

    // MARK: - Invitations

    /// Trips the signed-in user has been asked to join and hasn't answered.
    ///
    /// Built by hand rather than through `assemble`, because almost nothing is
    /// readable yet: `trips_read` gives the name, dates and cover, `profiles`
    /// is open so the faces resolve, and the two aggregate figures come from
    /// an RPC. The itinerary, the chat and the ledger stay hidden until the
    /// invitation is accepted — which is the point of the whole feature, so
    /// this reads exactly as much as the preview card needs and no more.
    ///
    /// Never throws. An invitation that fails to load should cost you the
    /// card, not your trips.
    func loadInvitations() async -> [TripInvitation] {
        guard let profile = try? await resolveProfile() else { return [] }

        let mine: [TripMemberRow] = (try? await client
            .from("trip_members")
            .select()
            .eq("profile_id", value: profile)
            .eq("status", value: "invited")
            .execute()
            .value) ?? []

        let tripIDs = mine.map(\.trip_id)
        guard !tripIDs.isEmpty else { return [] }

        async let tripRows: [TripRow]? = try? await client
            .from("trips").select().in("id", values: tripIDs).execute().value
        async let memberRows: [TripMemberRow]? = try? await client
            .from("trip_members").select().in("trip_id", values: tripIDs).execute().value
        async let profileRows: [ProfileRow]? = try? await client
            .from("profiles").select().execute().value

        guard let trips = await tripRows, let members = await memberRows, let profiles = await profileRows
        else { return [] }

        let byID = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.asTraveller(currentProfile: profile)) })
        let membersByTrip = Dictionary(grouping: members, by: \.trip_id)
        let inviteByTrip = Dictionary(uniqueKeysWithValues: mine.map { ($0.trip_id, $0) })

        var result: [TripInvitation] = []

        for row in trips {
            let tripMembers = membersByTrip[row.id] ?? []

            var trip = row.asTrip(
                travellers: tripMembers.compactMap { byID[$0.profile_id] },
                organiserIDs: Set(tripMembers.filter { $0.role == "organiser" }.map(\.profile_id)),
                invitedIDs: Set(tripMembers.filter(\.isInvited).map(\.profile_id)),
                items: []
            )

            if let summary: [TripPreviewRow] = try? await client
                .rpc("trip_invite_preview", params: ["p_trip": row.id.uuidString])
                .execute()
                .value,
               let preview = summary.first {
                trip.previewBookingCount = preview.booking_count
                trip.previewCost = preview.total_cost
            }

            let invite = inviteByTrip[row.id]
            result.append(
                TripInvitation(trip: trip, invitedByID: invite?.invited_by, invitedAt: invite?.invited_at)
            )
        }

        return result.sorted { ($0.invitedAt ?? .distantPast) > ($1.invitedAt ?? .distantPast) }
    }

    /// Asks somebody to join. Writes a `trip_members` row that is explicitly
    /// *not* active, which is what keeps them out of every share calculation
    /// until they say yes.
    func invite(_ traveller: Traveller, to tripID: UUID) async throws {
        let profile = try await resolveProfile()
        try await ensureProfiles(for: [traveller], excluding: profile)

        try await client
            .from("trip_members")
            .upsert(
                TripMemberRow(
                    trip_id: tripID,
                    profile_id: traveller.id,
                    role: "traveller",
                    status: "invited",
                    invited_by: profile,
                    invited_at: Date()
                ),
                onConflict: "trip_id,profile_id"
            )
            .execute()
    }

    /// Accepting flips the row to active — from there every existing policy
    /// treats them as a member and the trip loads in full on the next sync.
    func acceptInvitation(tripID: UUID) async throws {
        let profile = try await resolveProfile()

        try await client
            .from("trip_members")
            .update(["status": AnyJSON.string("active")])
            .eq("trip_id", value: tripID)
            .eq("profile_id", value: profile)
            .execute()
    }

    /// Declining removes the row outright. Nothing to preserve — they were
    /// never on the trip, so there's no history for anything to point at.
    func declineInvitation(tripID: UUID) async throws {
        let profile = try await resolveProfile()

        try await client
            .from("trip_members")
            .delete()
            .eq("trip_id", value: tripID)
            .eq("profile_id", value: profile)
            .execute()
    }

    // MARK: - Departures

    /// Writes a proposal or its answer. One row per person per trip — a
    /// departure is a state somebody is in, not an event log, and the unique
    /// constraint on `(trip_id, profile_id)` is what stops two devices racing
    /// into two conflicting exits for the same person.
    func upsertDeparture(_ departure: TripDeparture) async throws {
        try await client
            .from("trip_departures")
            .upsert(DepartureRow(departure), onConflict: "trip_id,profile_id")
            .execute()
    }

    func deleteDeparture(_ id: UUID) async throws {
        try await client.from("trip_departures").delete().eq("id", value: id).execute()
    }

    // MARK: - Audit trail

    /// One trip's history, newest first.
    ///
    /// Capped rather than paged: a trail is read by scrolling and searching,
    /// and a trip that has genuinely accrued more than a thousand recorded
    /// changes is one where the *recent* thousand is what anybody is looking
    /// at. RLS scopes the table to trips you're on, so there's nothing to
    /// filter here beyond the trip itself.
    func loadAuditEvents(tripID: UUID) async throws -> [AuditEvent] {
        let rows: [AuditEventRow] = try await client
            .from("trip_audit_events")
            .select()
            .eq("trip_id", value: tripID)
            .order("created_at", ascending: false)
            .limit(1000)
            .execute()
            .value

        return rows.map(\.asAuditEvent)
    }

    /// Files one entry.
    ///
    /// Non-throwing on purpose, and the only write in this file that is. An
    /// audit entry is a side effect of an action that has already happened and
    /// already reported its own success or failure; surfacing a second error
    /// for the bookkeeping would tell somebody their edit failed when it
    /// didn't. A row that doesn't land is simply absent from the trail, which
    /// the next load makes visible by omission.
    func recordAuditEvent(_ event: AuditEvent) async {
        guard let profile = try? await resolveProfile() else { return }
        _ = try? await client
            .from("trip_audit_events")
            .insert(AuditEventRow(event: event, actorProfileID: profile))
            .execute()
    }

    // MARK: - Notifications

    /// The signed-in user's notification feed. RLS already scopes the table to
    /// `current_profile_id()`, so there's nothing to filter here.
    func loadNotifications() async throws -> [AppNotification] {
        let profile = try await resolveProfile()

        let rows: [NotificationRow] = try await client
            .from("notifications")
            .select()
            .eq("profile_id", value: profile)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows.map(\.asNotification)
    }

    /// Files a notification for one person. Used when something changes under
    /// someone else — a new arrival on a trip recalculates everyone's share,
    /// and they should hear about it from the server, not from whichever
    /// device happened to make the change.
    func post(_ notification: AppNotification, to profileID: UUID) async {
        // Filing one for yourself is an ordinary insert; filing one for someone
        // else is not, and used to fail silently against `notifications_own`.
        // Every "you were added to a trip" the app thought it had sent was
        // rejected by RLS and swallowed by the `try?`. `notify_profile` is the
        // sanctioned way through: it checks you're both on the trip first.
        if profileID == currentProfileID {
            _ = try? await client
                .from("notifications")
                .insert(NotificationRow(notification: notification, profileID: profileID))
                .execute()
            return
        }

        guard let tripID = notification.tripID else { return }
        _ = try? await client.rpc(
            "notify_profile",
            params: [
                "p_profile": AnyJSON.string(profileID.uuidString),
                "p_trip": .string(tripID.uuidString),
                "p_kind": .string(notification.kind.rawValue),
                "p_title": .string(notification.title),
                "p_body": .string(notification.body),
                "p_settlement": notification.settlementID.map { AnyJSON.string($0.uuidString) } ?? .null
            ]
        ).execute()
    }

    /// Tells everyone else on a brand-new trip that they're on it.
    ///
    /// Being added to a shared ledger by somebody else is the single event most
    /// worth hearing about — it's a claim on your money — so it lands in-app
    /// the moment the trip saves rather than the next time you happen to open
    /// the app and notice a trip you don't remember joining.
    func announce(_ trip: Trip) async {
        guard let me = currentProfileID else { return }

        let others = trip.travellers.filter { $0.id != me }
        guard !others.isEmpty else { return }

        let body = trip.items.isEmpty
            ? "Nothing's booked yet."
            : "\(trip.items.count.pluralised("booking")) already on it, \(Money.format(trip.items.reduce(0) { $0 + $1.cost }, code: trip.currencyCode)) in total."

        for person in others {
            await post(
                AppNotification(
                    kind: .joined,
                    title: "\(CurrentUser.traveller.name) added you to \(trip.title)",
                    body: body,
                    tripID: trip.id
                ),
                to: person.id
            )
        }
    }

    func markNotificationRead(_ id: UUID) async {
        _ = try? await client
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: id)
            .execute()
    }

    func markAllNotificationsRead() async {
        guard let profile = try? await resolveProfile() else { return }
        _ = try? await client
            .from("notifications")
            .update(["is_read": true])
            .eq("profile_id", value: profile)
            .eq("is_read", value: false)
            .execute()
    }
}
