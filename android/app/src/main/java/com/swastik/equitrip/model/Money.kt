package com.swastik.equitrip.model

import java.text.NumberFormat
import java.util.Currency
import java.util.Locale
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.roundToLong

/**
 * Currency lives on the trip, not the app — a port of iOS `Money`, kept
 * arithmetic-for-arithmetic so both platforms show the same figure for the same row.
 */
object Money {
    fun format(amount: Double, code: String, signed: Boolean = false): String {
        val locale = if (code == "INR") Locale.forLanguageTag("en-IN") else Locale.US
        val formatter = NumberFormat.getCurrencyInstance(locale).apply {
            runCatching { currency = Currency.getInstance(code) }
            val whole = amount.roundToLong().toDouble() == amount
            maximumFractionDigits = if (whole) 0 else 2
            minimumFractionDigits = if (whole) 0 else 2
        }
        val magnitude = formatter.format(abs(amount))
        if (!signed) return magnitude
        return when {
            amount > 0 -> "+$magnitude"
            amount < 0 -> "−$magnitude"
            else -> magnitude
        }
    }

    /** Whole units per head, rounded down; `evenSplit` gives the remainder to one person. */
    private fun wholeShare(cost: Double, heads: Int): Double {
        if (heads <= 0) return 0.0
        val each = floor(abs(cost) / heads)
        return if (cost < 0) -each else each
    }

    /** Same as iOS: everybody gets a round number and `holder` absorbs the leftover. */
    fun evenSplit(cost: Double, heads: Int, holder: Int = 0): List<Double> {
        if (heads <= 0) return emptyList()
        val each = wholeShare(cost, heads)
        val parts = MutableList(heads) { each }
        val index = holder.coerceIn(0, heads - 1)
        parts[index] += cost - each * heads
        return parts
    }
}
