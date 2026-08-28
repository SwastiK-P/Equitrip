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
    /// Both fields go every time: choosing a memoji has to clear a photograph
    /// that was there before it, or the photo would keep winning and the pick
    /// would look like it did nothing.
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

        let memberships: [MembershipRow] = try await client
            .from("trip_members")
            .select("trip_id")
            .eq("profile_id", value: profile)
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

        let (trips, members, profiles, items) = try await (tripRows, memberRows, profileRows, itemRows)

        let itemIDs = items.map(\.id)
        let participantRows: [ParticipantRow] = itemIDs.isEmpty ? [] : (try await client
            .from("item_participants").select().in("item_id", values: itemIDs).execute().value)

        return assemble(
            trips: trips,
            members: members,
            profiles: profiles,
            items: items,
            participants: participantRows,
            me: profile
        )
    }

    /// Rebuilds the object graph the UI works in from six flat tables.
    private func assemble(
        trips: [TripRow],
        members: [TripMemberRow],
        profiles: [ProfileRow],
        items: [ItemRow],
        participants: [ParticipantRow],
        me: UUID
    ) -> [Trip] {
        let travellerByID = Dictionary(
            uniqueKeysWithValues: profiles.map { ($0.id, $0.asTraveller(currentProfile: me)) }
        )
        let membersByTrip = Dictionary(grouping: members, by: \.trip_id)
        let itemsByTrip = Dictionary(grouping: items, by: \.trip_id)
        let participantsByItem = Dictionary(grouping: participants, by: \.item_id)

        return trips.map { row in
            let tripMembers = membersByTrip[row.id] ?? []
            let travellers = tripMembers.compactMap { travellerByID[$0.profile_id] }

            let bookings = (itemsByTrip[row.id] ?? []).map { item in
                item.asItineraryItem(
                    participantIDs: Set((participantsByItem[item.id] ?? []).map(\.profile_id))
                )
            }

            return row.asTrip(
                travellers: travellers,
                organiserIDs: Set(tripMembers.filter { $0.role == "organiser" }.map(\.profile_id)),
                items: bookings
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
            TripMemberRow(
                trip_id: trip.id,
                profile_id: $0.id,
                role: trip.organiserIDs.contains($0.id) ? "organiser" : "traveller"
            )
        }
        try await client.from("trip_members").upsert(members).execute()
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
            item.participantIDs.map { ParticipantRow(item_id: item.id, profile_id: $0) }
        }
        guard !participants.isEmpty else { return }

        try await client.from("item_participants").insert(participants).execute()
    }

    func upsertItem(_ item: ItineraryItem, tripID: UUID) async throws {
        try await client.from("itinerary_items").upsert(ItemRow(item: item, tripID: tripID)).execute()
        try await client.from("item_participants").delete().eq("item_id", value: item.id).execute()

        guard !item.participantIDs.isEmpty else { return }
        let rows = item.participantIDs.map { ParticipantRow(item_id: item.id, profile_id: $0) }
        try await client.from("item_participants").insert(rows).execute()
    }

    func deleteItem(_ itemID: UUID) async throws {
        try await client.from("itinerary_items").delete().eq("id", value: itemID).execute()
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
                TripMemberRow(trip_id: tripID, profile_id: profile, role: "traveller"),
                ignoreDuplicates: true
            )
            .execute()

        return true
    }

    func setCover(_ url: String, tripID: UUID) async {
        _ = try? await client.from("trips").update(["cover_url": url]).eq("id", value: tripID).execute()
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
                "p_body": .string(notification.body)
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

// MARK: - Rows

struct ProfileRow: Codable {
    let id: UUID
    var user_id: UUID?
    var display_name: String
    var avatar_asset: String
    /// A photograph the person chose. `avatar_asset` is the memoji behind it,
    /// and stays the fallback so everybody has a face either way.
    var avatar_url: String?

    init(id: UUID, user_id: UUID?, display_name: String, avatar_asset: String, avatar_url: String? = nil) {
        self.id = id
        self.user_id = user_id
        self.display_name = display_name
        self.avatar_asset = avatar_asset
        self.avatar_url = avatar_url
    }

    /// The signed-in user keeps the app-wide "you" identity so every
    /// `isYou` check and avatar stays consistent with what's on device.
    func asTraveller(currentProfile: UUID) -> Traveller {
        id == currentProfile
            ? Traveller(
                id: id,
                name: CurrentUser.traveller.name,
                asset: CurrentUser.traveller.asset,
                avatarURL: CurrentUser.traveller.avatarURL
            )
            : Traveller(
                id: id,
                name: display_name,
                asset: avatar_asset,
                avatarURL: avatar_url.flatMap(URL.init(string:))
            )
    }
}

struct MembershipRow: Codable { let trip_id: UUID }

/// What `trip_preview` answers with: the two numbers the join screen states,
/// and deliberately nothing that would amount to handing over the itinerary.
struct TripPreviewRow: Decodable {
    let trip_id: UUID
    let booking_count: Int
    let total_cost: Double
}

struct NotificationRow: Codable {
    var id: UUID
    var profile_id: UUID
    var trip_id: UUID?
    var kind: String
    var title: String
    var body: String
    var is_read: Bool
    var created_at: Date

    init(notification: AppNotification, profileID: UUID) {
        id = notification.id
        profile_id = profileID
        trip_id = notification.tripID
        kind = notification.kind.rawValue
        title = notification.title
        body = notification.body
        is_read = !notification.isUnread
        created_at = notification.date
    }

    /// An unrecognised `kind` reads as `.booking` rather than being dropped —
    /// a notification whose glyph we can't pick is still worth showing.
    var asNotification: AppNotification {
        AppNotification(
            id: id,
            kind: ActivityEvent.Kind(rawValue: kind) ?? .booking,
            title: title,
            body: body,
            date: created_at,
            isUnread: !is_read,
            tripID: trip_id
        )
    }
}

struct TripMemberRow: Codable {
    var trip_id: UUID
    var profile_id: UUID
    var role: String
}

struct ParticipantRow: Codable {
    var item_id: UUID
    var profile_id: UUID
}

struct TripRow: Codable {
    var id: UUID
    var title: String
    var destination: String
    var start_date: String
    var end_date: String
    var currency_code: String
    var symbol: String
    var tint_hex: String
    var cover_url: String?
    var invite_code: String
    var created_by: UUID?

    init(trip: Trip, createdBy: UUID) {
        id = trip.id
        title = trip.title
        destination = trip.destination
        start_date = SupabaseFormat.day.string(from: trip.startDate)
        end_date = SupabaseFormat.day.string(from: trip.endDate)
        currency_code = trip.currencyCode
        symbol = trip.symbol
        tint_hex = "4B45C6"
        cover_url = trip.cover?.url.absoluteString
        invite_code = Trip.normaliseCode(trip.inviteCode)
        created_by = createdBy
    }

    func asTrip(travellers: [Traveller], organiserIDs: Set<UUID>, items: [ItineraryItem]) -> Trip {
        Trip(
            id: id,
            title: title,
            destination: destination,
            startDate: SupabaseFormat.day.date(from: start_date) ?? Date(),
            endDate: SupabaseFormat.day.date(from: end_date) ?? Date(),
            currencyCode: currency_code,
            symbol: symbol,
            tint: Palette.tint(forHex: tint_hex),
            travellers: travellers,
            items: items,
            organiserIDs: organiserIDs,
            cover: cover_url.flatMap(URL.init(string:)).map {
                TripPhoto(url: $0, thumbURL: $0, photographer: "", photographerURL: nil, sourceName: "")
            }
        )
    }
}

struct ItemRow: Codable {
    var id: UUID
    var trip_id: UUID
    var title: String
    var vendor: String
    var kind: String
    var day: String
    var start_time: Date?
    var cost: Double
    var split: String
    var photo_query: String?
    var cover_url: String?
    var suggested_symbol: String?
    /// The `flight` jsonb column. A whole sub-record that only applies to one
    /// kind of booking, so it rides as JSON rather than eleven mostly-null
    /// columns — see the note in `0001_init.sql`.
    var flight: FlightDetails?
    var paid_by: UUID?
    var payment_method: String?
    var receipt_url: String?
    var created_by: UUID?

    init(item: ItineraryItem, tripID: UUID) {
        id = item.id
        trip_id = tripID
        title = item.title
        vendor = item.vendor
        kind = item.kind.rawValue
        day = SupabaseFormat.day.string(from: item.day)
        start_time = item.time
        cost = item.cost
        split = item.split.rawValue
        photo_query = item.photoQuery
        cover_url = item.cover?.url.absoluteString
        suggested_symbol = item.suggestedSymbol
        flight = item.flight
        paid_by = item.paidByID
        payment_method = item.paymentMethod?.rawValue
        receipt_url = item.receiptURL?.absoluteString
        created_by = item.createdByID
    }

    func asItineraryItem(participantIDs: Set<UUID>) -> ItineraryItem {
        ItineraryItem(
            id: id,
            title: title,
            vendor: vendor,
            kind: ItineraryKind(rawValue: kind) ?? .other,
            date: SupabaseFormat.day.date(from: day) ?? Date(),
            time: start_time,
            cost: cost,
            split: SplitMode(rawValue: split) ?? .equal,
            participantIDs: participantIDs,
            photoQuery: photo_query,
            cover: cover_url.flatMap(URL.init(string:)).map {
                TripPhoto(url: $0, thumbURL: $0, photographer: "", photographerURL: nil, sourceName: "")
            },
            suggestedSymbol: suggested_symbol,
            flight: flight,
            paidByID: paid_by,
            paymentMethod: payment_method.flatMap(PaymentMethod.init(rawValue:)),
            receiptURL: receipt_url.flatMap(URL.init(string:)),
            createdByID: created_by
        )
    }
}

enum SupabaseFormat {
    /// Postgres `date` columns are plain calendar days with no zone; parsing
    /// them in the local zone is what keeps a booking on the day it was
    /// entered rather than sliding either side of midnight.
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}

extension Palette {
    static func tint(forHex hex: String) -> Color {
        switch hex.uppercased() {
        case "D97706": Palette.amber
        case "2F6FED": Palette.blue
        case "7C4DE0": Palette.violet
        case "0E7490": Palette.teal
        case "1E7A55": Palette.green
        default: AppTheme.accent
        }
    }
}
