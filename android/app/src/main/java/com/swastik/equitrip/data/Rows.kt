package com.swastik.equitrip.data

import kotlinx.serialization.Serializable

// Wire shapes of the Postgres rows, named as the columns are. Same tables as iOS
// `SupabaseRows.swift`; only the columns this app reads are declared.

@Serializable
data class ProfileRow(
    val id: String,
    val user_id: String? = null,
    val display_name: String,
    val avatar_asset: String = "",
    val avatar_url: String? = null,
    val upi_id: String? = null,
)

@Serializable
data class TripMemberRow(
    val trip_id: String,
    val profile_id: String,
    val role: String,
    val status: String? = null,
)

@Serializable
data class TripRow(
    val id: String,
    val title: String,
    val destination: String,
    val start_date: String,
    val end_date: String,
    val currency_code: String,
    val cover_url: String? = null,
    /** Null on rows written before migration 0019. */
    val title_style: String? = null,
    val invite_code: String = "",
)

@Serializable
data class ItemRow(
    val id: String,
    val trip_id: String,
    val title: String,
    val vendor: String = "",
    val kind: String,
    val day: String,
    val start_time: String? = null,
    val cost: Double,
    val split: String,
    val cover_url: String? = null,
    val paid_by: String? = null,
    val created_at: String? = null,
)

@Serializable
data class ParticipantRow(
    val item_id: String,
    val profile_id: String,
    /** Null means "on the booking"; a figure only exists for exact-amount splits. */
    val amount: Double? = null,
)

@Serializable
data class SettlementRow(
    val id: String,
    val trip_id: String,
    val from_profile: String,
    val to_profile: String,
    val amount: Double,
    val currency_code: String = "",
    val method: String = "cash",
    val status: String,
    val created_at: String,
)

@Serializable
data class NotificationRow(
    val id: String,
    val trip_id: String? = null,
    val kind: String,
    val title: String,
    val body: String = "",
    val is_read: Boolean,
    val created_at: String,
)
