//
//  ReceiptMoneyScanner.swift
//  Equitrip
//

import Foundation

/// A price found on a receipt row.
struct ReceiptPrice: Hashable {
    /// Signed: a price printed as "-40.00", "40.00-" or "(40.00)" is negative.
    var value: Double
    var hasDecimals: Bool
    var hasSign: Bool
    var currencyCode: String?
    /// The digits as printed, for repairs that depend on how they were written.
    var literal: String
    /// Which cell of the row it was in.
    var cell: Int
}

/// Finding prices in receipt text without mistaking everything else for one.
///
/// A receipt row is dense with numbers that aren't money: quantities, table
/// numbers, dates, clock times, tax rates, phone numbers, GSTINs, bill
/// numbers, HSN codes. `AmountScanner` in the Gmail reader can lean on a
/// currency symbol; receipts almost never print one beside each price. So
/// this works the other way round — everything that is recognisably *not* a
/// price is blanked out first, and what's left is read in every number format
/// tills print: 1,250.00, 1,23,456.00, 1.250,00, 12,50.
enum ReceiptMoneyScanner {

    static func prices(in row: ReceiptRow) -> [ReceiptPrice] {
        row.cells.enumerated().flatMap { index, cell in
            prices(inText: cell.text).map { found in
                var price = found
                price.cell = index
                return price
            }
        }
    }

    /// The rightmost price in a piece of text, in each of Vision's other
    /// readings of it. Used for the one price on a row the arithmetic cares
    /// about.
    static func alternatives(for cell: ReceiptCell, excluding value: Double) -> [Double] {
        var found: [Double] = []
        for reading in cell.alternatives {
            guard let last = prices(inText: reading).last?.value,
                  abs(last - value) > 0.004,
                  !found.contains(where: { abs($0 - last) < 0.004 }) else { continue }
            found.append(last)
        }
        return found
    }

    static func prices(inText raw: String) -> [ReceiptPrice] {
        let text = blankNoise(in: repairDigits(in: raw))
        let range = NSRange(text.startIndex..., in: text)

        return money.matches(in: text, range: range).compactMap { match in
            guard let literal = match.string(text, 3),
                  let parsed = number(from: literal) else { return nil }

            let leading = match.string(text, 1) ?? ""
            let trailing = match.string(text, 4) ?? ""
            // Brackets only mean negative around a price with decimals —
            // "(2)" beside an item is a quantity.
            let bracketed = leading == "(" && trailing == ")" && parsed.hasDecimals
            let negative = (!leading.isEmpty && leading != "(") || trailing == "-" || bracketed
            let symbol = match.string(text, 2)

            return ReceiptPrice(
                value: negative ? -parsed.value : parsed.value,
                hasDecimals: parsed.hasDecimals,
                hasSign: negative,
                currencyCode: symbol.flatMap { currency(for: $0) },
                literal: literal,
                cell: 0
            )
        }
        .filter { $0.value != 0 || $0.hasDecimals }
    }

    // MARK: - Number formats

    private static let money: NSRegularExpression = {
        let number = [
            #"\d{1,3}(?:\.\d{3})+,\d{2}"#,                    // 1.250,00
            #"\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?"#,             // 1,250.00
            #"\d{1,2}(?:,\d{2})+,\d{3}(?:\.\d{1,2})?"#,       // 1,23,456.00
            #"\d+\.\d{1,2}"#,                                  // 250.00
            #"\d+,\d{2}"#,                                     // 12,50
            #"\d+"#                                            // 250
        ].joined(separator: "|")

        // The last alternative is the rupee sign as recognition often reads
        // it — a P or an R glued to a price with paise — and only then.
        let symbols = #"₹|rs\.?|inr|us\$|usd|s\$|sgd|\$|€|eur|£|gbp|aed|thb|฿|¥|jpy|[₱PR](?=\d[\d,]*[.,]\d{2}(?!\d))"#

        // A price can follow "2 x" or "@", so x, X and @ are allowed right
        // before one; any other letter means it's part of a code ("A12").
        let pattern = #"(?<![A-WYZa-wyz0-9.,])([-−–(])?\s?("# + symbols + #")?\s?("# + number
            + #")(?![0-9])(?![.,][0-9])(-(?![0-9])|\))?(?!\s?%)(?![A-Za-z])"#
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()

    /// Reads one literal in whichever convention it was printed in.
    static func number(from literal: String) -> (value: Double, hasDecimals: Bool)? {
        var digits = literal
        var hasDecimals = false

        if literal.range(of: #"^\d{1,3}(?:\.\d{3})+,\d{2}$"#, options: .regularExpression) != nil {
            digits = literal.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            hasDecimals = true
        } else if literal.range(of: #"^\d+,\d{2}$"#, options: .regularExpression) != nil {
            digits = literal.replacingOccurrences(of: ",", with: ".")
            hasDecimals = true
        } else {
            digits = literal.replacingOccurrences(of: ",", with: "")
            hasDecimals = digits.contains(".")
        }

        guard let value = Double(digits) else { return nil }
        return (value, hasDecimals)
    }

    static func currency(for symbol: String) -> String? {
        switch symbol.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: " .")) {
        case "₹", "rs", "inr", "p", "r", "₱": "INR"
        case "$", "usd", "us$": "USD"
        case "s$", "sgd": "SGD"
        case "€", "eur": "EUR"
        case "£", "gbp": "GBP"
        case "aed": "AED"
        case "฿", "thb": "THB"
        case "¥", "jpy": "JPY"
        default: nil
        }
    }

    // MARK: - Repair

    private static let confusable: NSRegularExpression = try! NSRegularExpression(
        pattern: #"(?<![A-Za-z])[0-9OoIlSB|]*[0-9][0-9OoIlSB|]*[.,][0-9OoIlSB|]{2}(?![A-Za-z0-9])"#
    )

    /// Undoes the letter-for-digit swaps recognition makes in faded print —
    /// "1O5.OO" for 105.00, "S0.00" for 50.00 — but only inside something
    /// that is otherwise unmistakably a price: digits either side of a
    /// decimal point, and at least two of them real.
    static func repairDigits(in text: String) -> String {
        var output = text
        let matches = confusable.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches.reversed() {
            guard let range = Range(match.range, in: output) else { continue }
            let token = String(output[range])
            guard token.contains(where: { "OoIlSB|".contains($0) }),
                  token.filter(\.isNumber).count >= 2 else { continue }

            let fixed = String(token.map { character -> Character in
                switch character {
                case "O", "o": "0"
                case "I", "l", "|": "1"
                case "S": "5"
                case "B": "8"
                default: character
                }
            })
            output.replaceSubrange(range, with: fixed)
        }
        return output
    }

    // MARK: - Noise

    /// Numbers that are never prices, in the forms receipts print them.
    private static let noise: [NSRegularExpression] = [
        #"\b\d{2}[A-Z]{5}\d{4}[A-Z][A-Z0-9]{3}\b"#,                            // GSTIN
        #"(?:[xX]{2,}|\*{2,}|#{2,})[\s\-]?\d{3,4}\b"#,                          // card XXXX4821
        #"\b\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}\b"#,                             // 12/09/2026
        #"\b\d{4}[/.\-]\d{1,2}[/.\-]\d{1,2}\b"#,                               // 2026-09-12
        #"\b\d{1,2}(?:st|nd|rd|th)?[\s\-]?(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?[\s,\-]*\d{2,4}\b"#,
        #"\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s+\d{1,2},?\s+\d{4}\b"#,
        #"\b\d{1,2}:\d{2}(?::\d{2})?\s?(?:am|pm)?\b"#,                         // 19:42
        #"\b\d{1,2}[.]\d{2}\s?(?:am|pm)\b"#,                                   // 7.42 pm
        #"\(?\d{1,3}(?:[.,]\d{1,3})?\s?%\)?"#,                                  // 2.5%
        #"(?:\+\d{1,3}[\s\-]?)?\b\d{3,5}[\s\-]\d{5,8}\b"#,                     // 080-41234567
        #"\+\d{1,3}[\s\-]?\d[\d\s\-]{7,}\d"#,                                   // +91 98450 12345
        #"\b\d{7,}\b"#                                                          // bill and card numbers
    ].map { try! NSRegularExpression(pattern: $0, options: .caseInsensitive) }

    static func blankNoise(in text: String) -> String {
        var output = text
        for pattern in noise {
            let matches = pattern.matches(in: output, range: NSRange(output.startIndex..., in: output))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: output) else { continue }
                // Replaced with spaces rather than removed, so what was either
                // side of it doesn't join into one number.
                output.replaceSubrange(range, with: String(repeating: " ", count: output[range].count))
            }
        }
        return output
    }
}
