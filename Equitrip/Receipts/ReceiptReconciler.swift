//
//  ReceiptReconciler.swift
//  Equitrip
//

import Foundation

/// Makes a receipt's numbers agree with each other, or says exactly where they don't.
///
/// A receipt is self-checking: its items plus its taxes and charges equal its
/// total. That one equation is what separates this from reading text off a
/// picture, because it can arbitrate every ambiguity the page leaves open —
///
/// - which of two "total" lines is the one that was paid;
/// - whether the VAT line is added on top or already inside the prices;
/// - whether an unsigned "Round off 0.40" went up or down;
/// - and, when one price was misread, which of Vision's alternative readings
///   of those same characters is the real one.
///
/// Nothing here invents a number. Every substitution is a reading of printed
/// characters that recognition itself proposed, and it is only accepted when
/// it makes the whole receipt balance *and* no other substitution also would —
/// two equally good repairs means neither is trusted.
enum ReceiptReconciler {

    static func reconcile(_ parse: ReceiptParse, tookSecondLook: Bool = false) -> ReceiptScan {
        let first = settle(parse, tookSecondLook: tookSecondLook)
        guard !first.check.addsUp, parse.currencyCode == nil || parse.currencyCode == "INR" else { return first }

        // One glyph misread the same way on every line is a different kind of
        // mistake from one blurry digit, and has to be undone everywhere at
        // once: recognition that reads "₹" as "7" turns ₹650 into 7650 on
        // every priced row, and no single repair can make that balance.
        var unsigned = parse
        var changed = Set<String>()
        for index in unsigned.rows.indices {
            guard let price = unsigned.rows[index].price, let stripped = withoutRupeeSeven(price) else { continue }
            unsigned.rows[index].price?.value = stripped
            changed.insert(unsigned.rows[index].row.text)
        }
        guard !changed.isEmpty else { return first }

        var second = settle(unsigned, tookSecondLook: tookSecondLook)
        guard second.check.addsUp else { return first }
        second.corrections += changed.count
        for index in second.lines.indices where changed.contains(second.lines[index].source) {
            second.lines[index].wasCorrected = true
        }
        return second
    }

    private static func settle(_ parse: ReceiptParse, tookSecondLook: Bool) -> ReceiptScan {
        var rows = parse.rows
        demotePreTaxTotals(&rows)

        let totals = rows.filter { $0.role == .total && ($0.price?.value ?? 0) > 0 }
        let choices: [ReceiptParsedRow?] = totals.isEmpty ? [nil] : totals.map { $0 }

        let readings = choices.map { reading(of: rows, total: $0) }
        let best = readings.min { isBetter($0, $1) } ?? reading(of: rows, total: nil)

        let lines = best.items.enumerated().map { index, row in
            ReceiptLine(
                name: row.name.isEmpty ? "Item \(index + 1)" : row.name,
                quantity: row.quantity,
                unitPrice: row.unitPrice,
                amount: row.price?.value ?? 0,
                source: row.row.text,
                wasCorrected: best.corrected.contains(row.id)
            )
        }

        let charges = best.charges.map { row in
            ReceiptCharge(
                kind: row.role.chargeKind ?? .tax,
                label: chargeLabel(row),
                amount: signed(row, roundingSign: best.roundingSign),
                isIncluded: row.role == .tax && (row.isIncluded || best.taxIncluded)
            )
        }

        var scan = ReceiptScan(
            merchant: parse.merchant,
            date: parse.date,
            minuteOfDay: parse.minuteOfDay,
            currencyCode: parse.currencyCode,
            lines: lines,
            charges: charges,
            subtotal: best.subtotal?.price?.value,
            total: best.total?.price?.value,
            paymentMethod: parse.paymentMethod,
            cardLastFour: parse.cardLastFour,
            kind: parse.kind,
            check: .noTotal,
            corrections: best.corrected.count,
            usedModel: parse.usedModel,
            tookSecondLook: tookSecondLook,
            rowCount: parse.rows.count
        )
        scan.check = ReceiptCheck.of(
            items: scan.itemsTotal,
            charges: scan.chargesTotal,
            total: scan.total,
            hasItems: !scan.lines.isEmpty
        )
        return scan
    }

    /// Lower is better. For choosing between two readings of the same receipt
    /// — rules against the model, first look against second.
    static func rank(_ scan: ReceiptScan) -> Double {
        let size = max(1, scan.total ?? scan.itemsTotal)
        let base: Double = switch scan.check {
        case .balanced: 0
        case .rounded(let by): 0.05 + abs(by) / size
        case .unaccounted(let difference): 1 + min(1, abs(difference) / size)
        case .noTotal: scan.lines.isEmpty ? 5 : 3
        case .noItems: 4
        }
        return base + Double(scan.corrections) * 0.001
    }

    // MARK: - One reading

    private struct Reading {
        var items: [ReceiptParsedRow]
        var charges: [ReceiptParsedRow]
        var subtotal: ReceiptParsedRow?
        var total: ReceiptParsedRow?
        var taxIncluded: Bool
        var roundingSign: Double
        var corrected: Set<Int>
        var difference: Double?
        var isStrong: Bool
        var position: Int
    }

    private static func order(_ reading: Reading) -> (Int, Int, Int, Double) {
        let balanced = reading.difference.map { abs($0) <= ReceiptCheck.tolerance } ?? false
        let rounded = reading.difference.map { abs($0) < 1 } ?? false
        return (
            balanced ? 0 : (rounded ? 1 : 2),
            reading.isStrong ? 0 : 1,
            -reading.position,
            abs(reading.difference ?? .infinity)
        )
    }

    private static func isBetter(_ lhs: Reading, _ rhs: Reading) -> Bool {
        order(lhs) < order(rhs)
    }

    /// Every arrangement of the ambiguous parts, against one candidate total.
    private static func reading(of source: [ReceiptParsedRow], total: ReceiptParsedRow?) -> Reading {
        var rows = source
        // Items stop at the total — unless the total was printed above them,
        // as hotel folios and e-bills do.
        let firstItem = rows.first { $0.role == .item }?.id ?? 0
        let cutoff = total.flatMap { $0.id > firstItem ? $0.id : nil } ?? Int.max

        var items = rows.filter { $0.role == .item && ($0.price?.value ?? 0) > 0 && $0.id < cutoff }
        var charges = rows.filter { $0.role.chargeKind != nil && $0.price != nil && $0.id < cutoff }

        // "Total tax" beside the CGST and SGST it totals would count them twice.
        for kind in [ReceiptRole.tax, .discount] where charges.contains(where: { $0.role == kind && !$0.isAggregate }) {
            charges.removeAll { $0.role == kind && $0.isAggregate }
        }

        let subtotal = rows.last { $0.role == .subtotal && ($0.price?.value ?? 0) > 0 && $0.id < cutoff }
        let hasUnmarkedTax = charges.contains { $0.role == .tax && !$0.isIncluded }
        let hasUnsignedRounding = charges.contains { $0.role == .rounding && !($0.price?.hasSign ?? false) }

        // The plain reading — tax on top, round-off as printed — unless
        // another arrangement actually balances. Choosing "VAT included"
        // because it merely shrinks a gap that's there anyway is how a badly
        // read receipt ends up with its tax quietly struck out.
        var best: Reading? = arrange(items: items, charges: charges, subtotal: subtotal, total: total, taxIncluded: false, sign: 1)
        for taxIncluded in hasUnmarkedTax ? [false, true] : [false] {
            for sign in hasUnsignedRounding ? [1.0, -1.0] : [1.0] where taxIncluded || sign < 0 {
                let candidate = arrange(items: items, charges: charges, subtotal: subtotal, total: total, taxIncluded: taxIncluded, sign: sign)
                let settles = candidate.difference.map { abs($0) < 1 } ?? false
                if settles, best.map({ isBetter(candidate, $0) }) ?? true { best = candidate }
            }
        }

        guard let chosen = best, let total, let totalValue = total.price?.value else {
            return best ?? arrange(items: items, charges: charges, subtotal: subtotal, total: nil, taxIncluded: false, sign: 1)
        }
        guard let difference = chosen.difference, abs(difference) > ReceiptCheck.tolerance else { return chosen }

        // MARK: Repairs, most conservative first.

        let chargeSum = sum(chosen.charges, taxIncluded: chosen.taxIncluded, sign: chosen.roundingSign)

        // 1. One price misread — an item's, a charge's or the total's. First
        //    from what recognition itself offered: Vision's runner-up
        //    readings, the decimal point put back, a rupee sign read as 7.
        //    Only if none of those works, from the digit swaps faded print
        //    is known for: a slashed 0 read as 8, 5 as 6, 1 as 7. Either
        //    way, exactly one repair has to balance the receipt to the paisa.
        let itemSum = items.reduce(0) { $0 + ($1.price?.value ?? 0) }

        for tier in [Repair.printed, .confusable] {
            var fixes: [(row: Int, value: Double)] = []
            func consider(_ id: Int, _ value: Double) {
                if !fixes.contains(where: { $0.row == id && abs($0.value - value) < 0.004 }) {
                    fixes.append((id, value))
                }
            }

            for row in items {
                guard let old = row.price?.value else { continue }
                for alternative in readings(of: row, tier: tier)
                where abs(totalValue - (itemSum - old + alternative + chargeSum)) <= ReceiptCheck.tolerance {
                    consider(row.id, alternative)
                }
            }

            for row in chosen.charges where !(row.role == .tax && (row.isIncluded || chosen.taxIncluded)) {
                let old = signed(row, roundingSign: chosen.roundingSign)
                for alternative in readings(of: row, tier: tier) {
                    var reread = row
                    reread.price?.value = row.price.map { $0.value < 0 ? -alternative : alternative } ?? alternative
                    let new = signed(reread, roundingSign: chosen.roundingSign)
                    if abs(totalValue - (itemSum + chargeSum - old + new)) <= ReceiptCheck.tolerance {
                        consider(row.id, reread.price?.value ?? alternative)
                    }
                }
            }

            for alternative in readings(of: total, tier: tier)
            where abs(alternative - (itemSum + chargeSum)) <= ReceiptCheck.tolerance {
                consider(total.id, alternative)
            }

            // Two different repairs that would each balance: trust neither,
            // and don't go looking for a third among weaker evidence.
            if fixes.count > 1 { break }
            guard let fix = fixes.first else { continue }

            var repairedItems = items
            var charges = chosen.charges
            var fixedTotal = total
            if let index = repairedItems.firstIndex(where: { $0.id == fix.row }) {
                repairedItems[index].price?.value = fix.value
            } else if let index = charges.firstIndex(where: { $0.id == fix.row }) {
                charges[index].price?.value = fix.value
            } else {
                fixedTotal.price?.value = fix.value
            }

            // A digit swap that balances the receipt has only the one
            // equation behind it, and a line that was never read at all
            // leaves the same kind of gap: a missing ₹200 lassi and "640"
            // read for "840" are indistinguishable from the total alone. So a
            // swap is only trusted when the subtotal agrees with the repaired
            // items independently — as printed, or with its own digits swapped.
            if tier == .confusable {
                let repairedSum = repairedItems.reduce(0) { $0 + ($1.price?.value ?? 0) }
                var subtotals: [Double] = []
                if let subtotal, let printed = subtotal.price?.value {
                    subtotals = [printed] + readings(of: subtotal, tier: .confusable)
                }
                guard subtotals.contains(where: { abs($0 - repairedSum) <= ReceiptCheck.tolerance }) else { break }
            }
            items = repairedItems

            var repaired = arrange(items: items, charges: charges, subtotal: subtotal, total: fixedTotal, taxIncluded: chosen.taxIncluded, sign: chosen.roundingSign)
            repaired.corrected = [fix.row]
            return repaired
        }

        // 3. A priced line the rules didn't take as an item — a whole number
        //    among prices with paise, say — whose price, read as printed or
        //    with its decimal point back, is exactly what's missing.
        if difference > 0, let firstItem = items.first?.id {
            var missing: [(index: Int, value: Double, corrected: Bool)] = []
            for index in rows.indices {
                let row = rows[index]
                guard row.role == .unknown, row.id > firstItem, row.id < cutoff, row.letterCount >= 2,
                      let printed = row.price?.value else { continue }
                if abs(printed - difference) <= ReceiptCheck.tolerance {
                    missing.append((index, printed, false))
                } else if let reread = readings(of: row).first(where: { abs($0 - difference) <= ReceiptCheck.tolerance }) {
                    missing.append((index, reread, true))
                }
            }
            if missing.count == 1, let found = missing.first {
                rows[found.index].role = .item
                rows[found.index].price?.value = found.value
                items.append(rows[found.index])
                items.sort { $0.id < $1.id }
                var promoted = arrange(items: items, charges: chosen.charges, subtotal: subtotal, total: total, taxIncluded: chosen.taxIncluded, sign: chosen.roundingSign)
                if found.corrected { promoted.corrected.insert(rows[found.index].id) }
                return promoted
            }
        }

        return chosen
    }

    private static func arrange(
        items: [ReceiptParsedRow],
        charges: [ReceiptParsedRow],
        subtotal: ReceiptParsedRow?,
        total: ReceiptParsedRow?,
        taxIncluded: Bool,
        sign: Double
    ) -> Reading {
        let itemSum = items.reduce(0) { $0 + ($1.price?.value ?? 0) }
        let chargeSum = sum(charges, taxIncluded: taxIncluded, sign: sign)

        var difference = total?.price.map { $0.value - (itemSum + chargeSum) }

        // With no items read, a subtotal that balances still proves the
        // total and the charges were read right.
        if items.isEmpty, let subtotalValue = subtotal?.price?.value, let totalValue = total?.price?.value {
            difference = totalValue - (subtotalValue + chargeSum)
        }

        return Reading(
            items: items,
            charges: charges,
            subtotal: subtotal,
            total: total,
            taxIncluded: taxIncluded,
            roundingSign: sign,
            corrected: [],
            difference: difference,
            isStrong: total?.isStrongTotal ?? false,
            position: total?.id ?? 0
        )
    }

    // MARK: - Pieces

    /// A "Total" printed above the tax lines, with a bigger total below them,
    /// is the subtotal whatever it calls itself.
    private static func demotePreTaxTotals(_ rows: inout [ReceiptParsedRow]) {
        let totals = rows.indices.filter { rows[$0].role == .total && rows[$0].price != nil }
        for (current, next) in zip(totals, totals.dropFirst()) {
            guard let here = rows[current].price?.value, let there = rows[next].price?.value, there > here else { continue }
            let chargesBetween = rows[(current + 1)..<next].contains { $0.role.chargeKind != nil && $0.price != nil }
            if chargesBetween { rows[current].role = .subtotal }
        }
    }

    private static func sum(_ charges: [ReceiptParsedRow], taxIncluded: Bool, sign: Double) -> Double {
        charges.reduce(0) { total, row in
            if row.role == .tax, row.isIncluded || taxIncluded { return total }
            return total + signed(row, roundingSign: sign)
        }
    }

    private static func signed(_ row: ReceiptParsedRow, roundingSign: Double) -> Double {
        guard let price = row.price else { return 0 }
        switch row.role {
        case .discount:
            return -abs(price.value)
        case .rounding:
            return price.hasSign ? price.value : roundingSign * abs(price.value)
        default:
            return abs(price.value)
        }
    }

    private enum Repair { case printed, confusable }

    /// Every other way the printed price could be read, by strength of evidence.
    private static func readings(of row: ReceiptParsedRow, tier: Repair = .printed) -> [Double] {
        guard let price = row.price else { return [] }
        if tier == .confusable { return confusedReadings(of: price.literal) }

        var values = row.alternatives.map(abs)
        // "32000" for "320.00": the decimal point is the smallest thing on the
        // line and the likeliest to fade.
        if !price.hasDecimals, abs(price.value) >= 100 {
            values.append(abs(price.value) / 100)
        }
        if let stripped = withoutRupeeSeven(price) {
            values.append(abs(stripped))
        }
        return values.filter { $0 > 0 }
    }

    /// Digits recognition swaps in worn thermal print, and what each is
    /// mistaken for.
    private static let confusions: [Character: [Character]] = [
        "0": ["8", "6", "9"], "8": ["0", "3", "6"], "3": ["8"], "5": ["6"],
        "6": ["5", "8", "0"], "9": ["0", "4"], "4": ["9"], "1": ["7"], "7": ["1"]
    ]

    /// The literal with one or two of its digits swapped for the ones they're
    /// most often misread as: "1,850.08" can be "1,050.00".
    private static func confusedReadings(of literal: String) -> [Double] {
        let characters = Array(literal)
        let positions = characters.indices.filter { confusions[characters[$0]] != nil }
        guard positions.count <= 9 else { return [] }

        var found = Set<String>()
        for first in positions {
            for swap in confusions[characters[first]] ?? [] {
                var once = characters
                once[first] = swap
                found.insert(String(once))

                for second in positions where second > first {
                    for other in confusions[characters[second]] ?? [] {
                        var twice = once
                        twice[second] = other
                        found.insert(String(twice))
                    }
                }
            }
        }
        found.remove(literal)
        return found.compactMap { ReceiptMoneyScanner.number(from: $0)?.value }.filter { $0 > 0 }
    }

    /// The price without a leading 7 that was really a rupee sign.
    private static func withoutRupeeSeven(_ price: ReceiptPrice) -> Double? {
        let literal = price.literal
        guard price.currencyCode == nil, literal.hasPrefix("7"), literal.count >= 3 else { return nil }
        let rest = String(literal.dropFirst()).trimmingCharacters(in: CharacterSet(charactersIn: ","))
        guard rest.first?.isNumber == true, let value = ReceiptMoneyScanner.number(from: rest)?.value, value > 0 else { return nil }
        return price.value < 0 ? -value : value
    }

    private static func chargeLabel(_ row: ReceiptParsedRow) -> String {
        let label = row.label.trimmingCharacters(in: .whitespaces)
        guard label.filter(\.isLetter).count >= 2 else { return row.role.chargeKind?.label ?? "Charge" }
        return ReceiptParser.tidyName(label)
    }
}
