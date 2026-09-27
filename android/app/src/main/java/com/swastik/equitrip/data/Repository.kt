package com.swastik.equitrip.data

import com.swastik.equitrip.model.ActivityKind
import com.swastik.equitrip.model.AppNotification
import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.PaymentMethod
import com.swastik.equitrip.model.Settlement
import com.swastik.equitrip.model.SettlementStatus
import com.swastik.equitrip.model.SplitMode
import com.swastik.equitrip.model.TitleStyle
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.model.Trip
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.buildJsonArray
import com.swastik.equitrip.importer.ExtractedKind
import com.swastik.equitrip.importer.ImportedTrip
import java.nio.ByteBuffer
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.UUID
import java.time.LocalDate
import java.time.OffsetDateTime

/**
 * Everything that reads Postgres, mirroring iOS `SupabaseRepository.loadTrips`: accepted
 * memberships first, then the trips, rosters, bookings, participants and settlements behind
 * them, assembled into `Trip`s. Writes: notifications marked read, and a trip created from an
 * imported booking PDF (`createImportedTrip`) with its roster, bookings and audit row.
 */
class Repository(private val supabase: Supabase) {
    var me: ProfileRow? = null
        private set

    private inline fun <reified T> JsonElement.rows(): List<T> = supabase.json.decodeFromJsonElement<List<T>>(this)

    private fun inList(ids: Collection<String>) = "in.(${ids.joinToString(",")})"

    /** The signed-in user's profile, created if an older account never got one. */
    suspend fun resolveProfile(): ProfileRow {
        val session = supabase.session ?: throw SupabaseException("Not signed in", 401)
        me?.takeIf { it.user_id == session.userId }?.let { return it }

        val existing = supabase.select("profiles", "user_id" to "eq.${session.userId}", "limit" to "1")
            .rows<ProfileRow>().firstOrNull()
        val profile = existing ?: supabase.insert("profiles", buildJsonObject {
            put("user_id", session.userId)
            put("display_name", session.email?.substringBefore("@") ?: "Traveller")
        }).rows<ProfileRow>().first()
        me = profile
        return profile
    }

    fun forget() {
        me = null
    }

    suspend fun loadTrips(): List<Trip> = coroutineScope {
        val profile = resolveProfile()
        val tripIds = supabase.select("trip_members", "profile_id" to "eq.${profile.id}", "status" to "eq.active")
            .rows<TripMemberRow>().map { it.trip_id }.distinct()
        if (tripIds.isEmpty()) return@coroutineScope emptyList()

        val tripsCall = async { supabase.select("trips", "id" to inList(tripIds)).rows<TripRow>() }
        val membersCall = async { supabase.select("trip_members", "trip_id" to inList(tripIds)).rows<TripMemberRow>() }
        val itemsCall = async { supabase.select("itinerary_items", "trip_id" to inList(tripIds)).rows<ItemRow>() }
        val settlementsCall = async {
            runCatching { supabase.select("settlements", "trip_id" to inList(tripIds)).rows<SettlementRow>() }
                .getOrDefault(emptyList())
        }

        val members = membersCall.await()
        val items = itemsCall.await()
        val profilesCall = async {
            supabase.select("profiles", "id" to inList(members.map { it.profile_id }.distinct())).rows<ProfileRow>()
        }
        val participants = if (items.isEmpty()) emptyList() else
            supabase.select("item_participants", "item_id" to inList(items.map { it.id })).rows<ParticipantRow>()

        assemble(tripsCall.await(), members, profilesCall.await(), items, participants, settlementsCall.await())
            .sortedBy { it.startDate }
    }

    suspend fun loadNotifications(): List<AppNotification> {
        val profile = resolveProfile()
        return supabase.select(
            "notifications",
            "profile_id" to "eq.${profile.id}",
            "order" to "created_at.desc",
            "limit" to "100",
        ).rows<NotificationRow>().map {
            AppNotification(
                id = it.id,
                kind = ActivityKind.decode(it.kind),
                title = it.title,
                body = it.body,
                date = OffsetDateTime.parse(it.created_at),
                isUnread = !it.is_read,
                tripId = it.trip_id,
            )
        }
    }

    private val read = JsonObject(mapOf("is_read" to JsonPrimitive(true)))

    suspend fun markNotificationRead(id: String) = supabase.update("notifications", read, "id" to "eq.$id")

    suspend fun markAllNotificationsRead() {
        val profile = resolveProfile()
        supabase.update("notifications", read, "profile_id" to "eq.${profile.id}", "is_read" to "eq.false")
    }

    /**
     * Saves an imported trip the way iOS `OfflineOutbox.createTrip` does: the trip, you as
     * its organiser, its bookings with you on each, then the `trip_created` audit row.
     *
     * The trip goes first with `created_by` = you (RLS `trips_insert`), then the roster —
     * `members_insert` allows seeding it once while the trip is still empty — and only then
     * the bookings and audit row, which both require membership.
     */
    suspend fun createImportedTrip(trip: ImportedTrip, title: String): String {
        val profile = resolveProfile()
        val tripId = UUID.randomUUID()
        val id = tripId.toString()
        val day = DateTimeFormatter.ISO_LOCAL_DATE
        val zone = ZoneId.systemDefault()

        supabase.insertQuietly("trips", buildJsonObject {
            put("id", id)
            put("title", title)
            put("destination", trip.destination)
            put("start_date", trip.startDate.format(day))
            put("end_date", trip.endDate.format(day))
            put("currency_code", trip.currencyCode)
            put("symbol", symbolFor(trip.destination, title))
            put("tint_hex", "4B45C6")
            put("title_style", "classic")
            put("invite_code", inviteCode(tripId))
            put("created_by", profile.id)
        })
        supabase.insertQuietly("trip_members", buildJsonObject {
            put("trip_id", id)
            put("profile_id", profile.id)
            put("role", "organiser")
        })

        val items = trip.items.map { item -> UUID.randomUUID().toString() to item }
        if (items.isNotEmpty()) {
            supabase.insertQuietly("itinerary_items", buildJsonArray {
                items.forEach { (itemId, item) ->
                    val kind = when (item.kind) {
                        ExtractedKind.TRANSFER -> "drive"
                        else -> item.kind.name.lowercase()
                    }
                    add(buildJsonObject {
                        put("id", itemId)
                        put("trip_id", id)
                        put("title", item.title)
                        put("vendor", item.detail)
                        put("kind", kind)
                        put("day", item.day.format(day))
                        item.minuteOfDay?.let {
                            put("start_time", item.day.atTime(it / 60, it % 60).atZone(zone).toOffsetDateTime().toString())
                        }
                        put("cost", maxOf(0.0, item.amount))
                        // A row the document marked for one person isn't an even split.
                        put("split", when {
                            item.participantCount == 1 -> "individual"
                            item.kind == ExtractedKind.STAY || item.kind == ExtractedKind.ACTIVITY -> "participants"
                            else -> "equal"
                        })
                        put("created_by", profile.id)
                    })
                }
            })
            supabase.insertQuietly("item_participants", buildJsonArray {
                items.forEach { (itemId, _) ->
                    add(buildJsonObject { put("item_id", itemId); put("profile_id", profile.id) })
                }
            })
        }

        val total = trip.items.sumOf { it.amount }
        supabase.insertQuietly("trip_audit_events", buildJsonObject {
            put("id", UUID.randomUUID().toString())
            put("trip_id", id)
            put("kind", "trip_created")
            put("actor_profile_id", profile.id)
            put("actor_name", profile.display_name)
            put("subject_id", id)
            put("subject", title)
            put("summary", "Created $title")
            put("changes", buildJsonArray {
                listOf(
                    "Destination" to trip.destination,
                    "Dates" to "${trip.startDate.format(DateTimeFormatter.ofPattern("d MMM"))}–${trip.endDate.format(DateTimeFormatter.ofPattern("d MMM"))}",
                    "Currency" to trip.currencyCode,
                    "Travellers" to profile.display_name,
                ).filter { it.second.isNotEmpty() }.forEach { (field, value) ->
                    add(buildJsonObject { put("field", field); put("after", value) })
                }
            })
            if (total > 0) put("amount", total)
            put("currency_code", trip.currencyCode)
        })
        return id
    }

    /**
     * iOS `Trip.inviteCode`, normalised: six characters from the id's raw bytes, two bytes
     * each, from an alphabet with no vowels and no 0/O or 1/I. Same id, same code on both.
     */
    private fun inviteCode(id: UUID): String {
        val alphabet = "ACDEFGHJKLMNPQRTUVWXY3456789"
        val bytes = ByteBuffer.allocate(16).putLong(id.mostSignificantBits).putLong(id.leastSignificantBits).array()
        return (0 until 6).map { i ->
            val value = (bytes[i * 2].toInt() and 0xFF shl 8) or (bytes[i * 2 + 1].toInt() and 0xFF)
            alphabet[value % alphabet.length]
        }.joinToString("")
    }

    /** iOS `TripDraft.inferredSymbol`: a glyph from the destination, so the trip has an identity. */
    private fun symbolFor(destination: String, title: String): String {
        val text = "$destination $title".lowercase()
        fun any(vararg words: String) = words.any { it in text }
        return when {
            any("ski", "snow", "alps", "manali", "aspen", "winter") -> "snowflake"
            any("beach", "goa", "bali", "maldives", "island", "coast") -> "beach.umbrella.fill"
            any("trek", "hike", "mountain", "camp", "himalaya") -> "mountain.2.fill"
            any("backwater", "cruise", "lake", "boat", "kerala") -> "ferry.fill"
            any("safari", "forest", "wildlife", "national park") -> "leaf.fill"
            any("tokyo", "paris", "london", "city", "york", "dubai") -> "building.2.fill"
            else -> "suitcase.fill"
        }
    }

    private fun assemble(
        trips: List<TripRow>,
        members: List<TripMemberRow>,
        profiles: List<ProfileRow>,
        items: List<ItemRow>,
        participants: List<ParticipantRow>,
        settlements: List<SettlementRow>,
    ): List<Trip> {
        val travellerById = profiles.associate {
            it.id to Traveller(it.id, it.display_name, it.avatar_asset, it.avatar_url, it.upi_id)
        }
        val membersByTrip = members.groupBy { it.trip_id }
        val itemsByTrip = items.groupBy { it.trip_id }
        val participantsByItem = participants.groupBy { it.item_id }
        val settlementsByTrip = settlements.groupBy { it.trip_id }

        return trips.map { row ->
            val roster = membersByTrip[row.id].orEmpty()
            Trip(
                id = row.id,
                title = row.title,
                destination = row.destination,
                startDate = LocalDate.parse(row.start_date),
                endDate = LocalDate.parse(row.end_date),
                currencyCode = row.currency_code,
                coverUrl = row.cover_url,
                titleStyle = TitleStyle.decode(row.title_style),
                inviteCode = row.invite_code,
                travellers = roster.mapNotNull { travellerById[it.profile_id] },
                organiserIds = roster.filter { it.role == "organiser" }.map { it.profile_id }.toSet(),
                invitedIds = roster.filter { it.status == "invited" }.map { it.profile_id }.toSet(),
                items = itemsByTrip[row.id].orEmpty().map { item ->
                    val onItem = participantsByItem[item.id].orEmpty()
                    ItineraryItem(
                        id = item.id,
                        title = item.title,
                        vendor = item.vendor,
                        kind = ItineraryKind.decode(item.kind),
                        day = LocalDate.parse(item.day),
                        time = item.start_time?.let { runCatching { OffsetDateTime.parse(it) }.getOrNull() },
                        cost = item.cost,
                        split = SplitMode.decode(item.split),
                        participantIds = onItem.map { it.profile_id }.toSet(),
                        customShares = onItem.mapNotNull { p -> p.amount?.let { p.profile_id to it } }.toMap(),
                        paidById = item.paid_by,
                        coverUrl = item.cover_url,
                        createdAt = item.created_at?.let { runCatching { OffsetDateTime.parse(it) }.getOrNull() },
                    )
                },
                settlements = settlementsByTrip[row.id].orEmpty().map {
                    Settlement(
                        id = it.id,
                        fromId = it.from_profile,
                        toId = it.to_profile,
                        amount = it.amount,
                        currencyCode = it.currency_code.ifEmpty { row.currency_code },
                        method = PaymentMethod.decode(it.method),
                        status = SettlementStatus.entries.firstOrNull { s -> s.name.equals(it.status, true) }
                            ?: SettlementStatus.PENDING,
                        createdAt = OffsetDateTime.parse(it.created_at),
                    )
                },
            )
        }
    }
}
