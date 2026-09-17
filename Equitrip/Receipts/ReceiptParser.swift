//
//  ReceiptParser.swift
//  Equitrip
//

import CoreGraphics
import Foundation

/// A receipt row with a meaning attached.
struct ReceiptParsedRow: Identifiable {
    let row: ReceiptRow
    var id: Int { row.id }

    var role: ReceiptRole
    /// The row's price: the rightmost one on it.
    var price: ReceiptPrice?
    /// Vision's other readings of that price.
    var alternatives: [Double]
    /// Words left once the prices, quantities and serial numbers are gone.
    var label: String
    /// What an item is called, which can come from the row above it.
    var name: String
    var quantity: Double?
    var unitPrice: Double?
    var isStrongTotal: Bool
    var isAggregate: Bool
    var isIncluded: Bool
    /// A whole number sitting where prices with paise do: kept only so the
    /// reconciler can try it with its decimal point back, never as an item.
    var isSuspect: Bool = false

    var letterCount: Int { label.filter(\.isLetter).count }
}

/// The first reading of a receipt: every row, its role, and the facts around it.
struct ReceiptParse {
    var rows: [ReceiptParsedRow]
    var merchant: String
    var date: Date?
    var minuteOfDay: Int?
    var currencyCode: String?
    var paymentMethod: PaymentMethod?
    var cardLastFour: String?
    var kind: ItineraryKind
    var usedModel = false
}

/// Reads a receipt's rows by rule: prices by position, roles by vocabulary.
///
/// This is a complete reader on its own — it is what runs with no Apple
/// Intelligence — and it's also the ground truth the model is checked
/// against. The model may relabel a row; it may not move a price, because
/// every price here was found at a position on the page by this code.
///
/// The idea the layout rules are built on: a receipt is a table whose last
/// column is money. Find that column first — the right edge the most
/// decimal numbers line up against — and a number is a price when it sits in
/// it. The "4" of "Covers 4", the table number, the "2" of a quantity: all
/// numbers, none of them in that column.
enum ReceiptParser {

    struct PriceColumn {
        /// Normalised x of the column's right edge.
        var right: CGFloat
        /// Whether this till prints paise/cents. Most do; plenty of Indian
        /// restaurants print "320". When most prices have decimals, an
        /// integer in the column is a quantity or a code, not a price.
        var usesDecimals: Bool
    }

    static func parse(_ rows: [ReceiptRow], today: Date = Date()) -> ReceiptParse {
        let prices = rows.map { ReceiptMoneyScanner.prices(in: $0) }
        let column = priceColumn(rows, prices)

        var parsed = rows.indices.map { read(rows[$0], prices: prices[$0], column: column) }
        pullDownSummaryFigures(&parsed)
        attachWrappedNames(&parsed)
        confineItems(&parsed)

        let allText = rows.map(\.text).joined(separator: "\n")
        let tenderText = parsed.filter { $0.role == .tender }.map(\.row.text).joined(separator: "\n")
        let payment = ReceiptLexicon.paymentMethod(in: tenderText.isEmpty ? allText : tenderText)
        let fallbackPayment = payment.method == nil ? ReceiptLexicon.paymentMethod(in: allText) : payment
        let merchant = merchant(in: parsed)
        let items = parsed.filter { $0.role == .item }.map(\.name).joined(separator: " ")

        return ReceiptParse(
            rows: parsed,
            merchant: merchant,
            date: date(in: rows, today: today),
            minuteOfDay: minuteOfDay(in: rows),
            currencyCode: ReceiptLexicon.currency(in: allText),
            paymentMethod: fallbackPayment.method,
            cardLastFour: fallbackPayment.lastFour,
            kind: ReceiptLexicon.kind(for: "\(merchant)\n\(items)\n\(allText)")
        )
    }

    // MARK: - Column

    private static func priceColumn(_ rows: [ReceiptRow], _ prices: [[ReceiptPrice]]) -> PriceColumn? {
        var edges: [(right: CGFloat, decimals: Bool)] = []
        for (row, found) in zip(rows, prices) {
            guard let last = found.last, last.value != 0 else { continue }
            let cell = row.cells[last.cell]
            // Prices sit on the right. A number that ends in the left half of
            // the paper is an address, a date fragment or a table number.
            guard cell.maxX > 0.45 else { continue }
            edges.append((cell.maxX, last.hasDecimals))
        }
        guard edges.count >= 2 else { return nil }

        let usesDecimals = edges.filter(\.decimals).count * 2 >= edges.count
        let aligned = edges.filter { !usesDecimals || $0.decimals }.map(\.right).sorted()
        return PriceColumn(right: aligned[aligned.count / 2], usesDecimals: usesDecimals)
    }

    // MARK: - Rows

    private static func read(_ row: ReceiptRow, prices: [ReceiptPrice], column: PriceColumn?) -> ReceiptParsedRow {
        let (lexicon, readText) = reading(of: row)
        var role = lexicon.role
        var price = prices.last
        var suspect = false

        if let candidate = price {
            let cell = row.cells[candidate.cell]
            let inColumn = column.map { abs(cell.maxX - $0.right) < 0.13 } ?? (cell.maxX > 0.5)
            let integerInDecimalTill = (column?.usesDecimals ?? false) && !candidate.hasDecimals && candidate.currencyCode == nil

            if role.isSummary || role == .tender {
                // A total can be printed large and centred, or with its figure
                // alone — position is weaker evidence than the word "TOTAL".
                if integerInDecimalTill, prices.contains(where: \.hasDecimals) {
                    price = prices.last(where: \.hasDecimals)
                }
            } else if !inColumn {
                price = nil
            } else if integerInDecimalTill {
                // A whole number among prices with paise is usually a
                // quantity or a code — but it can be a price whose decimal
                // point faded. It stays on the row, unlabelled, for
                // `ReceiptReconciler` to try with the point put back.
                suspect = true
            }
        }

        // The label comes from whichever reading gave the role, so a tax
        // found in "CGST @2.5%" isn't then labelled "C6ST".
        let label = cleanLabel(readText)
        var quantity: Double?
        var unitPrice: Double?

        if let amount = price?.value, role == .unknown, !suspect {
            // A priced row that isn't a total, a tax or a table number is
            // something that was bought — including one with no words on it,
            // whose name `attachWrappedNames` finds on the row above.
            role = amount > 0 ? .item : .unknown
            (quantity, unitPrice) = quantities(in: row.text, prices: prices, amount: amount)
        } else if price == nil, role.isSummary, role != .total, role != .subtotal {
            // "GST No." and "Tax Invoice" name a tax and carry no money.
            role = .meta
        }

        let alternatives = price.map { ReceiptMoneyScanner.alternatives(for: row.cells[$0.cell], excluding: $0.value) } ?? []

        return ReceiptParsedRow(
            row: row,
            role: role,
            price: price,
            alternatives: alternatives,
            label: label,
            name: tidyName(label),
            quantity: quantity,
            unitPrice: unitPrice,
            isStrongTotal: lexicon.isStrongTotal,
            isAggregate: lexicon.isAggregate,
            isIncluded: lexicon.isIncluded,
            isSuspect: suspect
        )
    }

    /// The row's role, from its best reading or — when that says nothing —
    /// from Vision's other readings of the same cells.
    ///
    /// "C6ST @ 2.5%" with "CGST @2.5%" as the runner-up is a tax line, and
    /// dropping it because the first guess had a 6 in it loses a tax from
    /// the arithmetic. Only roles that name money or bookkeeping are taken
    /// from a runner-up: "Cash ew" is a worse reason to call cashews a
    /// payment than no reason at all.
    private static func reading(of row: ReceiptRow) -> (ReceiptLexicon.Reading, text: String) {
        var variants: [String] = []
        for (index, cell) in row.cells.enumerated() {
            for alternative in cell.alternatives.prefix(2) {
                var cells = row.cells.map(\.text)
                cells[index] = alternative
                variants.append(cells.joined(separator: "  "))
            }
        }

        let best = ReceiptLexicon.read(row.text)
        guard best.role == .unknown else {
            // Right role, garbled words — "C6ST" — and a runner-up that says
            // the same thing cleanly: show the runner-up.
            guard row.text.range(of: digitInWord, options: .regularExpression) != nil else { return (best, row.text) }
            let clean = variants.first {
                $0.range(of: digitInWord, options: .regularExpression) == nil && ReceiptLexicon.read($0).role == best.role
            }
            return (best, clean ?? row.text)
        }

        for variant in variants.prefix(8) {
            let other = ReceiptLexicon.read(variant)
            if other.role.isSummary || other.role == .meta { return (other, variant) }
        }
        return (best, row.text)
    }

    private static let digitInWord = #"[A-Za-z][0-9][A-Za-z]"#

    /// "2 x 180.00", "2 @ 180", or a quantity column and a rate column that
    /// multiply out to the row's amount. Only ever accepted when the
    /// arithmetic agrees: "Pepsi 2" could be two Pepsis or a two-litre one.
    private static func quantities(in text: String, prices: [ReceiptPrice], amount: Double) -> (Double?, Double?) {
        let range = NSRange(text.startIndex..., in: text)
        if let match = explicitQuantity.firstMatch(in: text, range: range),
           let count = match.string(text, 1).flatMap(Double.init), count > 0, count < 1000 {
            if let rateText = match.string(text, 2),
               let rate = ReceiptMoneyScanner.number(from: rateText)?.value,
               abs(count * rate - amount) < 0.02 * max(1, count) {
                return (count, rate)
            }
            if count == count.rounded(), abs(amount.truncatingRemainder(dividingBy: count)) < 0.001 || count <= 20 {
                return (count, amount / count)
            }
        }

        // "Chicken Biryani x 2", the delivery-app way round.
        if let match = trailingCount.firstMatch(in: text, range: range),
           let count = match.number(text, 1), count >= 2, count <= 20 {
            return (Double(count), amount / Double(count))
        }

        let before = prices.dropLast().map(\.value).filter { $0 > 0 }
        if before.count >= 2 {
            let a = before[before.count - 2]
            let b = before[before.count - 1]
            if a == a.rounded(), a < 1000, abs(a * b - amount) < 0.02 * max(1, a) { return (a, b) }
            if b == b.rounded(), b < 1000, abs(a * b - amount) < 0.02 * max(1, b) { return (b, a) }
        }
        if let only = before.last, only == only.rounded(), only >= 2, only <= 20,
           abs((amount / only) - (amount / only * 100).rounded() / 100) < 0.0001 {
            return (only, amount / only)
        }
        return (nil, nil)
    }

    private static let explicitQuantity = try! NSRegularExpression(
        pattern: #"(?<![\d.,])(\d{1,3}(?:\.\d{1,3})?)\s*(?:[xX×*](?![A-Za-z])|@|nos?\b\.?\s*[xX@]?|pcs?\b\.?\s*[xX@]?)\s*(?:rs\.?|₹|\$|€|£)?\s*([\d,]+(?:\.\d{1,2})?)?"#,
        options: .caseInsensitive
    )

    private static let trailingCount = try! NSRegularExpression(pattern: #"[A-Za-z)]\s+[xX×]\s?(\d{1,2})(?![\d.,])"#)

    // MARK: - Rows that belong together

    /// "TOTAL" on one line and "1,240.00" alone on the next.
    private static func pullDownSummaryFigures(_ rows: inout [ReceiptParsedRow]) {
        for index in rows.indices.dropLast() where rows[index].price == nil
            && (rows[index].role.isSummary || rows[index].role == .meta && ReceiptLexicon.read(rows[index].row.text).role.isSummary) {
            let next = index + 1
            guard let figure = rows[next].price, rows[next].letterCount < 2 else { continue }
            rows[index].role = ReceiptLexicon.read(rows[index].row.text).role
            rows[index].price = figure
            rows[index].alternatives = rows[next].alternatives
            rows[next].role = .absorbed
        }
    }

    /// An item name printed on its own line, with "2 x 180.00   360.00" under it.
    private static func attachWrappedNames(_ rows: inout [ReceiptParsedRow]) {
        for index in rows.indices.dropFirst() where rows[index].role == .item {
            let above = index - 1
            guard rows[above].role == .unknown, rows[above].price == nil, rows[above].letterCount >= 2 else { continue }

            if rows[index].letterCount < 2 {
                rows[index].name = tidyName(rows[above].label)
                rows[above].role = .absorbed
                continue
            }

            // "Mini Meals (South Indian" over "  Thali)  1  210  210": the
            // name ran out of paper. An open bracket above, or the priced
            // line indented under it, says the two are one name.
            let upper = rows[above].label
            let opens = upper.filter { $0 == "(" }.count > upper.filter { $0 == ")" }.count
            let trailsOff = upper.hasSuffix("&") || upper.hasSuffix(",") || upper.hasSuffix("/") || upper.lowercased().hasSuffix(" with")
            let indented = rows[index].row.minX > rows[above].row.minX + 0.02
            guard opens || trailsOff || indented else { continue }

            rows[index].name = tidyName(upper + " " + rows[index].label)
            rows[above].role = .absorbed
        }

        // A modifier under an item — "- extra cheese", "  with raita" — or the
        // second line of a name too long for the paper, indented under it.
        for index in rows.indices.dropLast() where rows[index].role == .item {
            let below = index + 1
            guard rows[below].role == .unknown, rows[below].price == nil, rows[below].letterCount >= 2 else { continue }
            // Unless the row after that is a price with no name: then this
            // line is that item's name, and the first pass already took it.
            if below + 1 < rows.count, rows[below + 1].role == .item, rows[below + 1].letterCount < 2 { continue }

            let text = rows[below].row.text.trimmingCharacters(in: .whitespaces)
            let isModifier = text.first.map { "-+*~>".contains($0) } ?? false
                || text.lowercased().hasPrefix("with ")
                || text.lowercased().hasPrefix("add ")
                || text.lowercased().hasPrefix("extra ")
            let isIndented = rows[below].row.minX > rows[index].row.minX + 0.03
            guard isModifier || isIndented else { continue }

            rows[index].name += (isModifier ? ", " : " ") + tidyName(rows[below].label)
            rows[below].role = .absorbed
        }
    }

    /// Items live between the header block and the first line that sums
    /// something up. A priced line above them is the bill number; one below
    /// them is the tax summary or the card slip.
    static func confineItems(_ rows: inout [ReceiptParsedRow]) {
        // Discounts and tips are left out of "first summary": supermarkets
        // print a discount straight under the item it applies to, and the
        // items carry on below it.
        //
        // Counted from the first item, not the top: a hotel folio or an e-bill
        // prints its total above everything it totals.
        let closing: Set<ReceiptRole> = [.subtotal, .total, .tax, .service]
        guard let firstItem = rows.firstIndex(where: { $0.role == .item }),
              let firstSummary = rows[firstItem...].firstIndex(where: { closing.contains($0.role) && $0.price != nil })
        else { return }

        let header = rows.firstIndex { $0.role == .header }
        let lastMetaAbove = rows[..<firstSummary].lastIndex { $0.role == .meta }
        let start: Int
        if let header, header < firstSummary {
            start = header + 1
        } else if let lastMetaAbove, lastMetaAbove < rows.count * 2 / 5,
                  rows[(lastMetaAbove + 1)..<firstSummary].contains(where: { $0.role == .item }) {
            start = lastMetaAbove + 1
        } else {
            start = 0
        }

        for index in rows.indices where rows[index].role == .item && (index < start || index > firstSummary) {
            rows[index].role = .unknown
        }
    }

    // MARK: - Labels

    /// Whole tokens only — each has to start after a space — so "Chips" keeps
    /// its "s" and "Coke 500ml" keeps its size.
    private static let trailingNumbers = try! NSRegularExpression(
        pattern: #"(?:(?:^|(?<=[\s:]))(?:[-−(·•]?(?:rs\.?|₹|\$|€|£|inr|[PR](?=\d))?\s?\d[\d,.]*[-)]?|[xX×]\d{1,3}|[xX×@*]|nos?\.?|pcs?\.?|qty)[\s:]*)+$"#,
        options: .caseInsensitive
    )
    /// A serial number, not a name that starts with one: "2 Masala Dosa"
    /// loses its 2, "7 Up" and "100 Pipers" keep theirs.
    private static let leadingSerial = try! NSRegularExpression(pattern: #"^\s*(?:#|s\.?\s?no\.?)?\s*(?:\d{1,3}[.)]|\d{1,2})\s+(?=[A-Za-z]{3,})"#, options: .caseInsensitive)
    private static let leadingQuantity = try! NSRegularExpression(pattern: #"^\s*\d{1,3}\s*[xX×]\s*"#)

    /// The words of a row, without the numbers that came with it.
    static func cleanLabel(_ text: String) -> String {
        var label = text
        for pattern in [trailingNumbers, leadingQuantity, leadingSerial] {
            label = pattern.stringByReplacingMatches(in: label, range: NSRange(label.startIndex..., in: label), withTemplate: "")
        }
        label = label.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return label.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ":-*.·|")))
    }

    /// "PANEER TIKKA" reads as shouting on a card; "Paneer Tikka" reads as
    /// food. Tax names stay in capitals — "Cgst" isn't anything.
    static func tidyName(_ label: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let letters = trimmed.filter(\.isLetter)
        guard letters.count >= 3, letters == letters.uppercased() else { return trimmed }

        return trimmed.lowercased().capitalized
            .split(separator: " ", omittingEmptySubsequences: false)
            .map { word in
                let bare = word.filter(\.isLetter).uppercased()
                return acronyms.contains(bare) ? word.uppercased() : String(word)
            }
            .joined(separator: " ")
    }

    private static let acronyms: Set<String> = [
        "GST", "CGST", "SGST", "IGST", "UTGST", "VAT", "HST", "PST", "UPI", "KOT", "MRP",
        "BBQ", "ATM", "USA", "UK", "LLP", "LLC", "IPA", "XL", "XXL", "KFC", "BPCL", "HPCL", "IOCL"
    ]

    // MARK: - Merchant

    /// The shop's name is near the top, printed biggest, and isn't an
    /// address, a GSTIN or the words "TAX INVOICE".
    private static func merchant(in rows: [ReceiptParsedRow]) -> String {
        let firstPriced = rows.firstIndex { $0.price != nil && ($0.role == .item || $0.role.isSummary) } ?? rows.count
        let window = rows.prefix(max(1, min(firstPriced, 10)))
        let heights = window.map(\.row.height).sorted()
        let typical = heights.isEmpty ? 0.02 : max(0.005, heights[heights.count / 2])

        let best = window.enumerated()
            .filter { _, row in
                row.row.text.filter(\.isLetter).count >= 3
                    && row.role != .header
                    && !ReceiptLexicon.isBoilerplate(row.row.text)
            }
            .max { lhs, rhs in score(lhs.element, at: lhs.offset, typical: typical) < score(rhs.element, at: rhs.offset, typical: typical) }

        guard let best else { return "" }
        let name = best.element.row.text
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        return tidyName(name)
    }

    private static func score(_ row: ReceiptParsedRow, at index: Int, typical: CGFloat) -> Double {
        var score = Double(row.row.height / typical) * 2
        if row.row.isTitle { score += 1.5 }
        score += index == 0 ? 0.8 : (index < 3 ? 0.4 : 0)
        let text = row.row.text
        let digits = Double(text.filter(\.isNumber).count)
        score -= digits / Double(max(1, text.count)) * 3
        return score
    }

    // MARK: - When

    /// The first date on the receipt that could be the day it was printed.
    ///
    /// "09/12/2026" is 9 December almost everywhere and 12 September in the
    /// US, and a receipt doesn't say which convention its till used. The
    /// tie-breaker is the calendar: a receipt can't be from the future, so
    /// whichever reading lands in the past wins, day-first when both do.
    static func date(in rows: [ReceiptRow], today: Date) -> Date? {
        let calendar = Calendar.current
        let earliest = calendar.date(byAdding: .year, value: -2, to: today) ?? today
        let latest = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let plausible = { (date: Date) in date >= earliest && date <= latest }

        for row in rows {
            let text = row.text

            if let match = numericDate.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let first = match.number(text, 1), let second = match.number(text, 2), var year = match.number(text, 3) {
                if year < 100 { year += 2000 }
                for (day, month) in [(first, second), (second, first)] {
                    guard (1...31).contains(day), (1...12).contains(month),
                          let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                          plausible(date) else { continue }
                    return date
                }
            }

            // Month names only with a year or the word "date" beside them:
            // otherwise "2 Mayo" is the second of May.
            let spaced = text.replacingOccurrences(of: #"(\d{1,2})-([A-Za-z]{3,9})-(\d{2,4})"#, with: "$1 $2 $3", options: .regularExpression)
            let anchored = spaced.range(of: #"\d{4}|date"#, options: [.regularExpression, .caseInsensitive]) != nil
            if anchored, let date = TravelDate.first(in: spaced, referenceDate: today), plausible(date) {
                return date
            }
        }
        return nil
    }

    private static let numericDate = try! NSRegularExpression(pattern: #"\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})\b"#)
    private static let clock = try! NSRegularExpression(pattern: #"\b(\d{1,2}):(\d{2})(?::\d{2})?\s*([ap]\.?m\.?)?|\b(\d{1,2})\.(\d{2})\s*([ap]\.?m\.?)"#, options: .caseInsensitive)

    /// A time is only taken with a colon, or a dot and am/pm — "12.50" on its
    /// own is a price far more often than it's ten to one.
    static func minuteOfDay(in rows: [ReceiptRow]) -> Int? {
        for row in rows {
            let text = row.text
            guard let match = clock.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { continue }

            let colon = match.number(text, 1) != nil
            guard var hour = match.number(text, colon ? 1 : 4),
                  let minute = match.number(text, colon ? 2 : 5) else { continue }

            if let meridiem = match.string(text, colon ? 3 : 6)?.lowercased().filter(\.isLetter) {
                if meridiem == "pm", hour < 12 { hour += 12 }
                if meridiem == "am", hour == 12 { hour = 0 }
            }
            guard (0...23).contains(hour), (0...59).contains(minute) else { continue }
            return hour * 60 + minute
        }
        return nil
    }
}
