package com.swastik.equitrip.model

import java.time.Duration
import java.time.OffsetDateTime

/** The `notifications.kind` values — iOS `ActivityEvent.Kind`. An unknown kind reads as `BOOKING`. */
enum class ActivityKind(val raw: String) {
    PAYMENT("payment"), RECALCULATION("recalculation"), REFUND("refund"), JOINED("joined"),
    BOOKING("booking"), INVITED("invited"), DEPARTURE_REQUESTED("departure_requested"), LEFT("left"),
    BOOKING_CHANGED("booking_changed"), BOOKING_REMOVED("booking_removed"), CONFIRMED("confirmed"),
    DISPUTED("disputed"), SETTLEMENT_REQUESTED("settlement_requested"),
    SETTLEMENT_CONFIRMED("settlement_confirmed"), SETTLEMENT_DECLINED("settlement_declined");

    companion object {
        fun decode(raw: String) = entries.firstOrNull { it.raw == raw } ?: BOOKING
    }
}

/** One entry in the bell's list, and in Home's recent activity. */
data class AppNotification(
    val id: String,
    val kind: ActivityKind,
    val title: String,
    val body: String,
    val date: OffsetDateTime,
    val isUnread: Boolean,
    val tripId: String?,
) {
    val time: String
        get() {
            val seconds = Duration.between(date, OffsetDateTime.now()).seconds
            return when {
                seconds < 60 -> "Just now"
                seconds < 3600 -> "${seconds / 60}m ago"
                seconds < 86_400 -> "${seconds / 3600}h ago"
                seconds < 172_800 -> "Yesterday"
                else -> "${seconds / 86_400}d ago"
            }
        }
}
