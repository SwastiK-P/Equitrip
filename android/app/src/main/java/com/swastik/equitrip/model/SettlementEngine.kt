package com.swastik.equitrip.model

import kotlin.math.abs
import kotlin.math.min
import kotlin.math.roundToLong

/**
 * Turns outstanding balances into the fewest transfers that clear them — the same two
 * passes as iOS `SettlementEngine`, so both apps suggest the same payments.
 */
object SettlementEngine {
    private const val EPSILON = 0.01

    private class Side(val id: String, var amount: Double)

    private fun cents(value: Double) = (value * 100).roundToLong() / 100.0

    fun minimalTransfers(balances: Map<String, Double>): List<Transfer> {
        val debtors = balances.filter { it.value < -EPSILON }.map { Side(it.key, -it.value) }
            .sortedByDescending { it.amount }
        val creditors = balances.filter { it.value > EPSILON }.map { Side(it.key, it.value) }
            .sortedByDescending { it.amount }
        val transfers = mutableListOf<Transfer>()

        // Pass one: a debt that exactly cancels a credit clears in one transfer.
        for (debtor in debtors) {
            if (debtor.amount <= EPSILON) continue
            val creditor = creditors.firstOrNull { abs(it.amount - debtor.amount) <= EPSILON } ?: continue
            transfers += Transfer(debtor.id, creditor.id, cents(debtor.amount))
            debtor.amount = 0.0
            creditor.amount = 0.0
        }

        // Pass two: largest against largest on whatever's left.
        var di = 0
        var ci = 0
        while (di < debtors.size && ci < creditors.size) {
            if (debtors[di].amount <= EPSILON) { di++; continue }
            if (creditors[ci].amount <= EPSILON) { ci++; continue }
            val amount = min(debtors[di].amount, creditors[ci].amount)
            val rounded = cents(amount)
            if (rounded > EPSILON) transfers += Transfer(debtors[di].id, creditors[ci].id, rounded)
            debtors[di].amount -= amount
            creditors[ci].amount -= amount
        }
        return transfers.sortedByDescending { it.amount }
    }
}
