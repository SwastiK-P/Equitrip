//
//  ReceiptScan.swift
//  Equitrip
//

import Foundation

/// A receipt, read: what was bought, what was added on top, and what it came to.
///
/// Every amount in here was printed on the paper. The reader chooses *which*
/// printed number means what — this line is an item, that one is CGST, the
/// one near the bottom is the total — and never produces a figure of its own.
/// The arithmetic in `ReceiptReconciler` only ever checks those choices
/// against each other, which is how a scan can say "this adds up" rather
/// than "this is probably right".
struct ReceiptScan: Equatable {
    /// The business, as printed. Empty when nothing near the top read as one.
    var merchant: String
    /// The day printed on the receipt, when it printed one that makes sense.
    var date: Date?
    /// Minutes since midnight. Nil when no time was printed.
    var minuteOfDay: Int?
    /// Nil when nothing on the paper said which currency it was in.
    var currencyCode: String?
    var lines: [ReceiptLine]
    var charges: [ReceiptCharge]
    var subtotal: Double?
    /// The printed grand total. Nil when the receipt never states one.
    var total: Double?
    var paymentMethod: PaymentMethod?
    var cardLastFour: String?
    /// A guess at the ledger category, never shown as a fact.
    var kind: ItineraryKind
    var check: ReceiptCheck
    /// How many prices were swapped for Vision's second reading of the same
    /// characters because the first reading didn't add up.
    var corrections: Int
    /// Whether Apple Intelligence labelled the rows, or rules alone did.
    var usedModel: Bool
    /// Whether a second recognition pass over the image was needed.
    var tookSecondLook: Bool
    var rowCount: Int

    var itemsTotal: Double { lines.reduce(0) { $0 + $1.amount } }

    /// Charges that change what was paid. Tax printed as "included" is
    /// already inside the item prices and adding it again would double it.
    var chargesTotal: Double {
        charges.filter { !$0.isIncluded }.reduce(0) { $0 + $1.amount }
    }

    /// What the expense is for: the printed total, or the parts when the
    /// receipt never printed one. To the paisa, never negative.
    var amountPaid: Double {
        max(0, ((total ?? itemsTotal + chargesTotal) * 100).rounded() / 100)
    }
}

/// One thing bought.
struct ReceiptLine: Identifiable, Equatable {
    let id: UUID
    var name: String
    /// Nil when the receipt doesn't print one, which means one.
    var quantity: Double?
    var unitPrice: Double?
    var amount: Double
    /// The row this was read from, for when a name was tidied beyond recognition.
    var source: String
    /// True when the first reading of the price didn't add up and Vision's
    /// alternative reading of the same characters did.
    var wasCorrected: Bool

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double? = nil,
        unitPrice: Double? = nil,
        amount: Double,
        source: String = "",
        wasCorrected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.amount = amount
        self.source = source
        self.wasCorrected = wasCorrected
    }
}

/// Something added to, or taken off, the items: tax, service, a tip, a discount.
struct ReceiptCharge: Identifiable, Equatable {
    enum Kind: String, CaseIterable {
        case tax, service, tip, discount, delivery, rounding

        var label: String {
            switch self {
            case .tax: "Tax"
            case .service: "Service charge"
            case .tip: "Tip"
            case .discount: "Discount"
            case .delivery: "Delivery"
            case .rounding: "Round off"
            }
        }

        var symbol: String {
            switch self {
            case .tax: "percent"
            case .service: "bell"
            case .tip: "heart"
            case .discount: "tag"
            case .delivery: "shippingbox"
            case .rounding: "plusminus"
            }
        }
    }

    let id: UUID
    var kind: Kind
    /// As printed: "CGST 2.5%", "Service Charge @10%".
    var label: String
    /// Signed. A discount is negative however the receipt printed it.
    var amount: Double
    /// Printed for information only — "VAT included" — and not added on top.
    var isIncluded: Bool

    init(id: UUID = UUID(), kind: Kind, label: String, amount: Double, isIncluded: Bool = false) {
        self.id = id
        self.kind = kind
        self.label = label
        self.amount = amount
        self.isIncluded = isIncluded
    }
}

/// Whether the parts of a receipt agree with its total.
enum ReceiptCheck: Equatable {
    /// Items and charges come to the printed total, to the paisa.
    case balanced
    /// Off by less than one unit on a whole-number total — a till rounding
    /// the bill without printing a round-off line.
    case rounded(by: Double)
    /// Total minus everything else. Positive means something printed wasn't
    /// read as an item or a charge.
    case unaccounted(Double)
    /// A total, and nothing itemised above it.
    case noItems
    /// Items, and no total printed below them.
    case noTotal

    /// Tolerance for "adds up": sums of two-decimal prices are exact, so this
    /// only absorbs floating point.
    static let tolerance = 0.015

    static func of(items: Double, charges: Double, total: Double?, hasItems: Bool) -> ReceiptCheck {
        guard let total else { return .noTotal }
        guard hasItems else { return .noItems }

        let difference = total - (items + charges)
        if abs(difference) <= tolerance { return .balanced }
        if abs(difference) < 1, total.rounded() == total { return .rounded(by: difference) }
        return .unaccounted(difference)
    }

    var addsUp: Bool {
        switch self {
        case .balanced, .rounded: true
        default: false
        }
    }
}
