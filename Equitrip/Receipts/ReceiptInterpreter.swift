//
//  ReceiptInterpreter.swift
//  Equitrip
//

import Foundation
import FoundationModels

// MARK: - Schema

/// What the on-device model is asked about a receipt.
///
/// No numbers. The model is shown the receipt's rows with their prices and
/// asked what each priced row *is* — an item, a tax, the total, the card slip
/// — and what an item is called. It never reports an amount, because every
/// amount was already found at a position on the page by `ReceiptParser`, and
/// a figure the model typed would be a figure nobody could check.
@Generable(description: "How to read the rows of one shop, restaurant, hotel or travel receipt")
private struct ReceiptReading {

    @Guide(description: "The name of the business, copied exactly as it is printed near the top. Not the address, not 'Tax Invoice'. Empty string if no business name is printed.")
    var merchant: String

    @Guide(description: "What the money was spent on.")
    var spend: ReceiptSpend

    @Guide(description: "One entry for every priced row listed, in the same order.")
    var rows: [ReceiptRowLabel]
}

@Generable(description: "What one priced row of a receipt is")
private struct ReceiptRowLabel {

    @Guide(description: "The row's number, exactly as shown in square brackets.")
    var row: Int

    @Guide(description: "What this row's price is.")
    var kind: ReceiptRowKind

    @Guide(description: "Only for an item: what was bought, copied from that row's words, without quantity, codes or price. Empty string for every other kind of row.")
    var name: String
}

@Generable
private enum ReceiptRowKind {
    /// Something bought: food, a drink, a product, a ticket, a room night.
    case item
    case subtotal
    /// GST, CGST, SGST, IGST, VAT, cess, sales tax.
    case tax
    /// Service charge, cover, packing or container charge.
    case serviceCharge
    case tip
    case discount
    case deliveryFee
    case roundOff
    /// The final amount to pay.
    case total
    /// How it was paid: cash tendered, change, card, UPI.
    case payment
    /// Table, covers, invoice number, "Total Qty", a tax summary table.
    case other
}

@Generable
private enum ReceiptSpend {
    case restaurant, cafe, bar, groceries, hotel, transport, fuel, tickets, shopping, other
}

// MARK: - Interpreter

/// The judgement pass: which printed line is which, read by Apple Intelligence.
///
/// Rules handle the vocabulary of receipts well and their *meaning* badly. A
/// line reading "Kingfisher Ultra 650ml" and one reading "Service @ 10%" are
/// both a few words and a price; only reading them tells you one is beer and
/// the other a charge. The same goes for the merchant: the model can tell a
/// brewery's name from the street it's on without a list of street words.
///
/// Its answer goes through three filters before it's used. Row numbers must
/// point at rows that actually carry a price. Names must be words from that
/// row. The merchant must be printed near the top. And the whole relabelled
/// receipt then has to add up at least as well as the rules' own reading did —
/// `ReceiptReader` keeps whichever balances better.
@MainActor
enum ReceiptInterpreter {

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private static let instructions = """
        You read the rows of a receipt that has already been scanned, and say \
        what each priced row is.

        Rules:
        - Copy. A name must be words taken from its own row. Never invent, \
        translate or tidy a name.
        - Never report a number other than a row number.
        - An item is something bought. Tax, service charge, discount, tip and \
        round off are not items, even though they have prices.
        - The total is the final amount paid. "Total Qty" and "Total Items" \
        are other.
        - A tax summary or GST breakdown printed after the total is other.
        - Cash tendered, change returned and card slip lines are payment.
        """

    /// The receipt, relabelled — or nil when the model isn't there or its
    /// answer didn't survive checking.
    static func interpret(_ parse: ReceiptParse) async -> ReceiptParse? {
        guard isAvailable else { return nil }

        let priced = parse.rows.filter { $0.price != nil && $0.role != .absorbed && !$0.isSuspect }
        guard !priced.isEmpty else { return nil }

        // The context window is a few thousand tokens; a long supermarket
        // receipt is not. Rows are capped, and each one is clipped.
        let shown = parse.rows.prefix(90)
        let listing = shown.map { row in
            "[\(row.id)] \(String(row.row.text.prefix(64)))"
        }.joined(separator: "\n")
        let pricedList = priced.prefix(60).map { String($0.id) }.joined(separator: ", ")

        let prompt = """
            Receipt rows, top to bottom:
            \(listing)

            Priced rows to label: \(pricedList)
            """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let reading = try await session.respond(
                to: prompt,
                generating: ReceiptReading.self,
                options: GenerationOptions(sampling: .greedy)
            ).content
            return apply(reading, to: parse)
        } catch {
            return nil
        }
    }

    // MARK: - Checking the answer

    private static func apply(_ reading: ReceiptReading, to parse: ReceiptParse) -> ReceiptParse? {
        var relabelled = parse
        var labelled = 0

        for label in reading.rows {
            guard let index = relabelled.rows.firstIndex(where: { $0.id == label.row }),
                  relabelled.rows[index].price != nil,
                  relabelled.rows[index].role != .absorbed,
                  !relabelled.rows[index].isSuspect else { continue }

            let row = relabelled.rows[index]
            let role = role(for: label.kind)

            // The rules found "CGST", "Service Charge" or "TOTAL" printed on
            // this row. The model's opinion of what that row is can't beat
            // the words on it — it has called a service charge a tax, and
            // that decides whether the charge is counted.
            if row.role.isSummary { continue }

            relabelled.rows[index].role = role
            relabelled.rows[index].isStrongTotal = row.isStrongTotal || (role == .total && row.role != .total)
            labelled += 1

            if role == .item {
                let name = label.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if isCopied(name, from: row) {
                    relabelled.rows[index].name = ReceiptParser.tidyName(name)
                }
            }
        }

        guard labelled > 0 else { return nil }

        // Same boundaries the rules draw: nothing above the header block or
        // below the first total is an item, whoever labelled it.
        ReceiptParser.confineItems(&relabelled.rows)

        let merchant = reading.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let top = parse.rows.prefix(12).map(\.row.text).joined(separator: " ")
        if merchant.count >= 2, normalised(top).contains(normalised(merchant)), !ReceiptLexicon.isBoilerplate(merchant) {
            relabelled.merchant = ReceiptParser.tidyName(merchant)
        }

        // The category only fills a gap the rules left. Words on the bill
        // beat the model's impression of a name: it reads "Hotel Saravana
        // Bhavan" as somewhere to sleep, where the rules saw a dosa.
        if parse.kind == .other, let kind = kind(for: reading.spend) {
            relabelled.kind = kind
        }
        relabelled.usedModel = true
        return relabelled
    }

    /// Whether every word of the name is on the row, allowing for the model
    /// fixing the case.
    private static func isCopied(_ name: String, from row: ReceiptParsedRow) -> Bool {
        let words = normalised(name, keepingSpaces: true).split(separator: " ")
        guard !words.isEmpty, name.filter(\.isLetter).count >= 2 else { return false }
        let source = normalised(row.row.text + " " + row.name, keepingSpaces: true)
        return words.allSatisfy { source.contains($0) }
    }

    private static func normalised(_ text: String, keepingSpaces: Bool = false) -> String {
        String(text.lowercased().unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0) || (keepingSpaces && $0 == " ")
        })
    }

    private static func role(for kind: ReceiptRowKind) -> ReceiptRole {
        switch kind {
        case .item: .item
        case .subtotal: .subtotal
        case .tax: .tax
        case .serviceCharge: .service
        case .tip: .tip
        case .discount: .discount
        case .deliveryFee: .delivery
        case .roundOff: .rounding
        case .total: .total
        case .payment: .tender
        case .other: .meta
        }
    }

    private static func kind(for spend: ReceiptSpend) -> ItineraryKind? {
        switch spend {
        case .restaurant, .cafe, .bar, .groceries: .meal
        case .hotel: .stay
        case .transport, .fuel: .drive
        case .tickets, .shopping: .activity
        case .other: nil
        }
    }
}
