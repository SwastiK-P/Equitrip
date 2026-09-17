//
//  ReceiptLexicon.swift
//  Equitrip
//

import Foundation

/// What a priced row on a receipt is.
enum ReceiptRole: String {
    case item, subtotal, tax, service, tip, discount, delivery, rounding, total
    /// How it was paid: cash tendered, change, a card slip.
    case tender
    /// Numbers that aren't money: table, covers, bill number, GSTIN.
    case meta
    /// "Item  Qty  Rate  Amount".
    case header
    /// A row whose words were taken by another row — a wrapped item name,
    /// or a "TOTAL" label whose figure was printed on the line below.
    case absorbed
    case unknown

    var chargeKind: ReceiptCharge.Kind? {
        switch self {
        case .tax: .tax
        case .service: .service
        case .tip: .tip
        case .discount: .discount
        case .delivery: .delivery
        case .rounding: .rounding
        default: nil
        }
    }

    /// Rows that sum things up. Items don't come after the first of these.
    var isSummary: Bool {
        chargeKind != nil || self == .subtotal || self == .total
    }
}

/// The vocabulary of receipts: which words mark a total, a tax, a tip.
///
/// Receipts are written by tills, and tills print from a small, stubborn
/// vocabulary — so this is one of the places where rules beat the model. A
/// word list is never confused about whether CGST is a tax. It is, however,
/// confused by order: "Total Tax" is a tax, "CGST on total" is a tax, "Grand
/// Total (incl. GST)" is a total. Each check below runs in the order that
/// resolves those collisions, and the order is the part to be careful with.
enum ReceiptLexicon {

    struct Reading {
        var role: ReceiptRole
        /// "Grand total" rather than "total", when there are two.
        var isStrongTotal = false
        /// "Total tax" beside the CGST and SGST rows it adds up.
        var isAggregate = false
        /// "VAT included": printed for information, already in the prices.
        var isIncluded = false
    }

    static func read(_ text: String) -> Reading {
        let lower = undoLetterSwaps(text.lowercased())

        if matches(rounding, lower) { return Reading(role: .rounding) }
        if matches(subtotal, lower) { return Reading(role: .subtotal) }
        if matches(countTotals, lower) { return Reading(role: .meta) }
        if matches(taxTotals, lower) { return Reading(role: .tax, isAggregate: true, isIncluded: matches(included, lower)) }
        if matches(discountTotals, lower) { return Reading(role: .discount, isAggregate: true) }
        if matches(strongTotal, lower) { return Reading(role: .total, isStrongTotal: true) }
        if matches(taxNames, lower), !matches(notTax, lower) {
            return Reading(role: .tax, isIncluded: matches(included, lower))
        }
        if matches(service, lower) { return Reading(role: .service) }
        if matches(delivery, lower) { return Reading(role: .delivery) }
        if matches(tip, lower) { return Reading(role: .tip) }
        if matches(discount, lower) { return Reading(role: .discount) }
        if matches(tender, lower) { return Reading(role: .tender) }
        if matches(plainTotal, lower) { return Reading(role: .total) }
        if matches(meta, lower) { return Reading(role: .meta) }
        if headerWords(in: lower) >= 2 { return Reading(role: .header) }
        return Reading(role: .unknown)
    }

    // MARK: - Roles

    private static let rounding = regex(#"round(?:ed|ing)?[\s\-]?off|\brounding\b|\brnd\s?off\b|\badj(?:ustment)?\b"#)
    private static let subtotal = regex(#"sub[\s\-]?total|\bitems?\s?total|gross\s?(?:amount|amt|total|value)|basic\s?(?:amount|amt)|taxable\s?(?:amount|amt|value)|amount\s?before\s?tax|total\s?before\s?tax|food\s?total|\bnet\s?sales\b"#)
    private static let countTotals = regex(#"total\s?(?:qty|quantity|items?|no\.?\s?of|pcs|count)|no\.?\s?of\s?items|items?\s?count|you\s?(?:have\s?)?saved|total\s?savings"#)
    private static let taxTotals = regex(#"total\s?(?:tax(?:es)?|gst|vat)|(?:tax|gst|vat)\s?total"#)
    private static let discountTotals = regex(#"total\s?discounts?|discount\s?total"#)
    private static let strongTotal = regex(#"grand\s?total|net\s?payable|amount\s?payable|total\s?payable|amount\s?due|balance\s?due|total\s?due|net\s?(?:amount|amt)|bill\s?(?:amount|amt|total)|invoice\s?(?:total|amount|value)|total\s?(?:amount|amt|bill|inr|rs\b|₹|usd|eur|gbp|aed|sgd|thb)|amount\s?to\s?(?:be\s?)?pa(?:y|id)|\bto\s?pay\b|final\s?(?:amount|total)|\bnett?\s?total|total\s?(?:incl|inc\.)"#)
    private static let taxNames = regex(#"\bc\.?\s?gst\b|\bs\.?\s?gst\b|\bi\.?\s?gst\b|\butgst\b|\bgst\b|\bvat\b|\btax(?:es)?\b|\bcess\b|\bhst\b|\bpst\b|\bmwst\b|\btva\b|\biva\b|\bkkc\b|\bsbc\b"#)
    private static let notTax = regex(#"tax\s?invoice|gstin|gst\s?(?:no|num|reg|#|:)|vat\s?(?:no|reg|#|:)|tax\s?summary|tax\s?details|\btaxable\b"#)
    private static let included = regex(#"\bincl|\binclusive|\bincludes?\b|\binc\.\s"#)
    private static let service = regex(#"service\s?(?:charge|chg|chrg|fee|amount|amt)|\bsvc\b|\bs/?c\b(?=\s*[@\d(])|cover\s?charge|packing|packaging|container\s?charge|convenience\s?fee|platform\s?fee|handling\s?(?:fee|charge)"#)
    private static let delivery = regex(#"delivery\s?(?:fee|charge|charges|partner)|\bshipping\b"#)
    private static let tip = regex(#"\btips?\b|gratuity"#)
    private static let discount = regex(#"discount|\bdisc\b|\bdisc\.|\bpromo|coupon|voucher|\boffer\b|\bsavings?\b|\bless\b|loyalty|instant\s?off|\bcomp(?:limentary)?\b"#)
    private static let tender = regex(#"\bcash\b|tendered|\bchange\b|\bcard\b|\bvisa\b|master\s?card|\bamex\b|rupay|\bupi\b|\bpaid\b|\bpayment\b|\bg\s?pay\b|google\s?pay|phonepe|paytm|\bwallet\b|\bcredit\b|\bdebit\b|net\s?banking|\bauth\b|approval|\bappr\b|\btxn\b|\brrn\b|\bbalance\b"#)
    private static let plainTotal = regex(#"\btotal\b|\btot\b|\bttl\b|\bamt\s?due\b|\bnet\b"#)
    private static let meta = regex(#"gstin|fssai|\binvoice\b|bill\s?(?:no|number|#)|receipt\s?(?:no|number|#)|\btable\b|\btbl\b|\bcovers?\b|\bpax\b|\bguests?\b|\bserver\b|cashier|steward|captain|waiter|\bkot\b|order\s?(?:no|#|id|type)|\btoken\b|\bph(?:one)?\b|\btel\b|\bmob(?:ile)?\b|thank|visit\s?again|www\.|\.com\b|\bhsn\b|\bsac\b|terms|e\s?&\s?o\s?e|\bdate\b|\btime\b|\bcin\b|\bpan\b|\btin\b|\bpos\b|terminal|\bmid\b|\btid\b|\bbatch\b|\bstan\b|\bshift\b|\bcounter\b|\bseat\b|\broom\s?no\b"#)

    private static let headerVocabulary = ["item", "items", "description", "particulars", "qty", "quantity", "rate", "price", "amount", "amt", "value", "mrp", "hsn", "sl", "sno"]

    /// The swaps recognition makes inside the handful of words this file
    /// cares most about: "C6ST" for CGST, "T0TAL" for TOTAL, "5UB TOTAL".
    /// `ReceiptMoneyScanner.repairDigits` does the reverse inside prices.
    private static func undoLetterSwaps(_ lower: String) -> String {
        var text = lower
        for (pattern, template) in letterSwaps {
            text = pattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
        }
        return text
    }

    private static let letterSwaps: [(NSRegularExpression, String)] = [
        (regex(#"\b([csiu]?)[6b]st(in)?\b"#), "$1gst$2"),
        (regex(#"\bt[o0]t[a4][l1i]\b"#), "total"),
        (regex(#"\b[5s]ub[\s\-]?t[o0]t[a4][l1i]\b"#), "subtotal"),
        (regex(#"\bv[a4]t\b"#), "vat"),
        (regex(#"\bd[i1l]sc[o0]unt\b"#), "discount")
    ]

    static func headerWords(in lower: String) -> Int {
        let words = Set(lower.split(whereSeparator: { !$0.isLetter }).map(String.init))
        return headerVocabulary.filter(words.contains).count
    }

    // MARK: - Merchant

    private static let boilerplate = regex(#"tax\s?invoice|\binvoice\b|\breceipt\b|cash\s?memo|\bbill\b|welcome|\boriginal\b|duplicate|\bcopy\b|\bestimate\b|dine[\s\-]?in|take[\s\-]?away|\bparcel\b|gstin|fssai|\bcin\b|www\.|\.com\b|@|\bph(?:one)?\b|\btel\b|\bmob|\bdate\b|\btime\b|\bcashier\b|\btable\b|\bserver\b"#)
    private static let address = regex(#"\broad\b|\brd\b|\bstreet\b|\bst\.|nagar\b|\blane\b|\bmarg\b|\bfloor\b|\bnear\b|\bopp\b|\bsector\b|\bblock\b|\blayout\b|\bcross\b|\bcolony\b|\bavenue\b|\bave\b|\bsuite\b|\bpin\b|\bdist\b|\bplot\b|\bshop\s?no\b"#)

    /// Whether a line near the top reads as anything other than the name of
    /// the place: the address, the GSTIN, "TAX INVOICE", a phone number.
    static func isBoilerplate(_ text: String) -> Bool {
        let lower = text.lowercased()
        if matches(boilerplate, lower) { return true }
        let digits = lower.filter(\.isNumber).count
        if matches(address, lower), digits > 0 { return true }
        // A postcode, or a line that's mostly numbers.
        if lower.range(of: #"\b\d{5,6}\b"#, options: .regularExpression) != nil { return true }
        return digits * 2 > lower.filter(\.isLetter).count
    }

    // MARK: - Category

    private static let kinds: [(ItineraryKind, NSRegularExpression)] = [
        (.stay, regex(#"room\s?(?:no|tariff|charges?|rent)|check[\s\-]?(?:in|out)\b|\bnights?\b|\bresort\b|\bhostel\b|\bhomestay\b|\blodge\b|\bfolio\b|\bairbnb\b"#)),
        (.drive, regex(#"\bfuel\b|\bpetrol\b|\bdiesel\b|indian\s?oil|\biocl\b|bharat\s?petroleum|\bbpcl\b|hindustan\s?petroleum|\bhpcl\b|\bshell\b|\blitres?\b|\bltrs?\b|\btaxi\b|\bcab\b|\buber\b|\bola\b|rapido|\bparking\b|\btoll\b|fastag|car\s?rental|bike\s?rental|scooty|scooter"#)),
        (.train, regex(#"\birctc\b|railway|\btrain\b|\bmetro\b"#)),
        (.flight, regex(#"\bairlines?\b|boarding\s?pass|excess\s?baggage"#)),
        (.activity, regex(#"\btickets?\b|\bentry\b|admission|\bmuseum\b|\bsafari\b|\bcinema\b|\bpvr\b|\binox\b|\bspa\b|massage|\bdiving\b|\btrek|rafting|parasail|\btour\b|amusement|water\s?park"#)),
        (.meal, regex(#"restaurant|\bcaf[eé]\b|coffee|\bbar\b|\bpub\b|brew|bistro|kitchen|dhaba|bakery|pizza|burger|\bfood\b|\bdine\b|diner|eatery|\bgrill\b|\bchai\b|\btea\b|juice|biryani|bhavan|sweets|canteen|\bkot\b|\bcovers\b|\bpax\b|swiggy|zomato|starbucks|mcdonald|\bkfc\b|domino|subway|\bbeer\b|\bwine\b|cocktail|mocktail|\bthali\b|\bdosa\b|\bnaan\b|paneer|chicken|masala|\bfries\b|\bsoda\b|mojito|sandwich|dessert|ice\s?cream|service\s?charge|\bdine[\s\-]?in\b|\btable\b"#))
    ]

    static func kind(for text: String) -> ItineraryKind {
        let lower = text.lowercased()
        let scored = kinds.map { kind, pattern in
            (kind, pattern.numberOfMatches(in: lower, range: NSRange(lower.startIndex..., in: lower)))
        }
        guard let best = scored.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return .other }
        return best.0
    }

    // MARK: - Currency

    private static let currencySignals: [(String, NSRegularExpression)] = [
        ("INR", regex(#"₹|\brs\.?\s?\d|\binr\b|\bgstin\b|\bc\.?gst\b|\bs\.?gst\b|\bfssai\b|\brupay\b|\bupi\b|\bpaise\b"#)),
        ("SGD", regex(#"s\$|\bsgd\b"#)),
        ("USD", regex(#"(?<![a-z])\$|\busd\b"#)),
        ("EUR", regex(#"€|\beur\b|\bmwst\b|\btva\b|\biva\b"#)),
        ("GBP", regex(#"£|\bgbp\b"#)),
        ("AED", regex(#"\baed\b|\bdhs?\b|dirham"#)),
        ("THB", regex(#"฿|\bthb\b|\bbaht\b"#)),
        ("JPY", regex(#"¥|\bjpy\b|円"#))
    ]

    static func currency(in text: String) -> String? {
        let lower = text.lowercased()
        let votes = currencySignals.map { code, pattern in
            (code, pattern.numberOfMatches(in: lower, range: NSRange(lower.startIndex..., in: lower)))
        }
        guard let best = votes.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        return best.0
    }

    // MARK: - Payment

    private static let upi = regex(#"\bupi\b|\bg\s?pay\b|google\s?pay|phonepe|paytm|\bbhim\b|\bvpa\b"#)
    private static let card = regex(#"\bcard\b|\bvisa\b|master\s?card|\bamex\b|rupay|\bcredit\b|\bdebit\b|contactless|\bchip\b|\bpos\b"#)
    private static let cash = regex(#"\bcash\b(?!\s?(?:ier|back))"#)
    private static let lastFour = regex(#"(?:x{2,}|\*{2,}|#{2,})[\s\-]?(\d{4})\b"#)

    static func paymentMethod(in text: String) -> (method: PaymentMethod?, lastFour: String?) {
        let lower = text.lowercased()
        let range = NSRange(lower.startIndex..., in: lower)
        let four = lastFour.firstMatch(in: lower, range: range).flatMap { $0.string(lower, 1) }

        if four != nil || matches(card, lower) { return (.card, four) }
        if matches(upi, lower) { return (.upi, nil) }
        if matches(cash, lower) { return (.cash, nil) }
        return (nil, nil)
    }

    // MARK: - Helpers

    static func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }

    static func matches(_ pattern: NSRegularExpression, _ text: String) -> Bool {
        pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
