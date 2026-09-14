//
//  ExpenseMailReader.swift
//  Equitrip
//

import FoundationModels
import Foundation

// MARK: - Schema

/// What the on-device model is asked to report about one email.
///
/// The amount is a `String`, which looks like a mistake and isn't. A `Double`
/// field lets the model *compute* — round 479.50 to 480, add a convenience
/// fee, carry a digit — and there is then no way to tell a copied number from
/// a computed one. Asking for the characters means the answer can be held
/// against the email afterwards: if the string it returned isn't in the mail,
/// it didn't read it there. That check is `ExpenseMailReader.verify`, and it
/// is the only reason any of this can be trusted with money.
@Generable(description: "What a bank or payment notification email says about a single payment")
private struct MailReading {

    @Guide(description: """
        True only when this email tells the account holder that money has \
        ALREADY left their own account, card or wallet. False for anything \
        arriving, anything scheduled, anything that failed, a statement, a \
        balance, a reminder, a one-time password, or an advertisement.
        """)
    var isPayment: Bool

    @Guide(description: """
        The amount that left the account, copied from the email exactly as its \
        digits are written. Digits and at most one decimal point. No currency \
        symbol, no commas, no rounding. If the email states no amount, this is \
        an empty string. Never calculate it.
        """)
    var amount: String

    @Guide(description: "Three-letter code of the currency: INR when the email says Rs or ₹, otherwise USD, EUR or GBP as written.")
    var currency: String

    @Guide(description: """
        Who received the money, copied exactly as the email writes it — a UPI \
        id like 'ravi@okhdfc', a merchant name, a shop. Empty string when the \
        email does not name one. Never invent a name and never tidy one up.
        """)
    var payee: String

    @Guide(description: "The transaction, reference or UPI number, copied exactly. Empty string when the email gives none.")
    var reference: String

    @Guide(description: "How the money moved, according to the email.")
    var channel: MailChannel

    @Guide(description: """
        True when this payment is an online purchase — an order, a delivery, or \
        a receipt from a shopping website or app — rather than something spent \
        in person while travelling.
        """)
    var isOnlineOrder: Bool
}

@Generable
private enum MailChannel {
    case upi
    case card
    case netBanking
    case wallet
    case unknown
}

// MARK: - Reader

/// Reads one email, on this device, and decides whether it is a payment.
///
/// Three passes, and the order matters. `ExpenseMailGate` throws out anything
/// that obviously isn't money leaving an account, so the model is asked about
/// a handful of emails rather than a mailbox. The model reads what is left,
/// which is the part no rule set does well — "paid to SWIGGY LIMITED" and
/// "your Swiggy order has shipped" differ by meaning, not by keyword. Then
/// every field it returned is checked back against the email text, and
/// anything it can't have read there is dropped.
///
/// Nothing leaves the phone at any point. The email was fetched from Gmail
/// over TLS, held in memory, read by Apple's on-device model, and reduced to
/// an amount and a name. No email body is ever written to disk or sent
/// anywhere.
@MainActor
enum ExpenseMailReader {

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private static let instructions = """
        You read one bank, card or payment-app notification email and report \
        only what it says.

        Rules:
        - Copy. Never calculate, never round, never tidy. Every field you fill \
        in must appear in the email in those characters.
        - When the email does not say something, the field is empty. An empty \
        field is a correct answer; a plausible one is not.
        - Money leaving the account is a payment. Money arriving — a credit, a \
        refund, cashback, a salary — is not, however similar the email looks. \
        Read the sentence the amount is in, not the rest of the email: \
        "Rs.90 has been credited to your account" is money arriving even when \
        the email is headed "Transaction Details", and an email that names a \
        "Sender" is describing somebody paying you.
        - A payment that has not happened yet is not a payment: reminders, \
        due dates, standing instructions, failed and declined transactions.
        - An advertisement that mentions a price is not a payment.
        """

    /// Returns a detection, or nil when this email is not a payment worth
    /// showing. Nil is the common answer and is not a failure.
    static func read(_ message: MailMessage, tripID: UUID) async -> DetectedExpense? {
        guard case .worthReading = ExpenseMailGate.check(message) else { return nil }

        let source = message.readableText

        guard isAvailable else {
            // No Apple Intelligence on this device. The pattern reader is
            // narrower — it only recognises the shapes it was taught — but it
            // is never *wrong* in the way a model can be, because it can only
            // return text it literally found.
            return patternRead(message, tripID: tripID)
        }

        do {
            let session = LanguageModelSession(instructions: instructions)
            let reading = try await session.respond(
                to: "Read this email.\n\n\(source)",
                generating: MailReading.self
            ).content

            guard reading.isPayment else { return nil }
            return verify(reading, message: message, tripID: tripID)
        } catch {
            return patternRead(message, tripID: tripID)
        }
    }

    // MARK: - Verification

    /// Holds the model's answer against the email it read.
    ///
    /// Each field fails on its own terms. An unverifiable payee is blanked,
    /// not fatal — the mail may genuinely not name one, and quick add asks for
    /// a title anyway. An unverifiable *amount* is fatal, unless the pattern
    /// scanner independently found exactly one, in which case that one is used
    /// and the detection is marked `.likely` so the card says to check it.
    private static func verify(
        _ reading: MailReading,
        message: MailMessage,
        tripID: UUID
    ) -> DetectedExpense? {
        let source = message.readableText

        // The model does not get a vote on direction. It said `isPayment` for
        // an HDFC credit alert whose body reads "has been successfully
        // credited to your account", and no amount of prompt wording makes a
        // small model reliable about a fact that is sitting there in the text.
        // Where the email is explicit, the email wins.
        guard MoneyDirection.of(source) != .incoming else { return nil }

        let haystack = source.lowercased()

        let claimed = Double(reading.amount.replacingOccurrences(of: ",", with: ""))
        let scanned = AmountScanner.candidates(in: source)

        let amount: Double
        let confidence: DetectedExpense.Confidence

        if let claimed, claimed > 0, AmountScanner.contains(claimed, in: source) {
            amount = claimed
            confidence = .certain
        } else if let only = soleAmount(in: scanned) {
            amount = only
            confidence = .likely
        } else {
            // The model produced a figure this email doesn't contain, and the
            // text has several candidates with no way to choose. Showing a
            // number here would be worse than showing nothing.
            return nil
        }

        // Only what the email actually contains survives — and the model's
        // answer is only preferred when the scanner didn't find a human name.
        // A model asked for "who received the money" will happily return the
        // VPA when the name is sitting in brackets right beside it.
        let scannedPayee = PayeeReader.payee(in: message.payeeSearchText, excluding: message.fromAddress)
        let claimedPayee = reading.payee.trimmingCharacters(in: .whitespacesAndNewlines)

        let payee: String
        if !scannedPayee.isEmpty, !scannedPayee.contains("@") {
            payee = scannedPayee
        } else if claimedPayee.count >= 2,
                  message.payeeSearchText.lowercased().contains(claimedPayee.lowercased()) {
            payee = claimedPayee
        } else {
            payee = scannedPayee
        }

        let reference = haystack.contains(reading.reference.lowercased()) && reading.reference.count >= 4
            ? reading.reference.trimmingCharacters(in: .whitespacesAndNewlines)
            : (AmountScanner.reference(in: source) ?? "")

        let currency = currencyCode(
            claimed: reading.currency,
            scanned: scanned,
            source: source
        )

        return DetectedExpense(
            id: message.id,
            tripID: tripID,
            amount: amount,
            currencyCode: currency,
            payee: String(payee.prefix(60)),
            reference: String(reference.prefix(32)),
            channel: channel(from: reading.channel, message: message),
            receivedAt: message.receivedAt,
            sender: message.fromName,
            subject: message.subject,
            relevance: reading.isOnlineOrder || MerchantIndex.isOnlineShopping(source)
                ? .onlineOrder
                : .trip,
            confidence: confidence,
            status: .waiting,
            detectedAt: Date()
        )
    }

    /// One distinct figure in the mail means there's nothing to choose between.
    /// Two figures that happen to be equal — the amount and the running total,
    /// on a first transaction — still count as one.
    private static func soleAmount(in candidates: [AmountScanner.Candidate]) -> Double? {
        let distinct = Set(candidates.map { ($0.value * 100).rounded() })
        guard distinct.count == 1, let only = distinct.first, only > 0 else { return nil }
        return only / 100
    }

    private static func currencyCode(
        claimed: String,
        scanned: [AmountScanner.Candidate],
        source: String
    ) -> String {
        let upper = claimed.uppercased().filter(\.isLetter)
        if ["INR", "USD", "EUR", "GBP", "AED", "SGD", "JPY", "AUD", "CAD", "THB"].contains(upper) {
            return upper
        }
        if let symbolled = scanned.compactMap(\.currencyCode).first { return symbolled }
        // An Indian bank writing "Rs." without a code is by far the common case.
        return source.contains("₹") ? "INR" : AppSettings.defaultCurrency
    }

    private static func channel(from claimed: MailChannel, message: MailMessage) -> DetectedExpense.Channel {
        let text = message.readableText.lowercased()
        // The text wins over the model here: "UPI" appearing in an alert is
        // unambiguous, and this is a field where being confidently wrong costs
        // nothing to avoid.
        if text.contains("upi")
            || PayeeReader.mentionsVPA(in: message.payeeSearchText, excluding: message.fromAddress) {
            return .upi
        }
        if text.contains("credit card") || text.contains("debit card") || text.contains("card ending") { return .card }
        if text.contains("net banking") || text.contains("neft") || text.contains("imps") || text.contains("rtgs") { return .netBanking }

        return switch claimed {
        case .upi: .upi
        case .card: .card
        case .netBanking: .netBanking
        case .wallet: .wallet
        case .unknown: .other
        }
    }

    // MARK: - Without the model

    /// The same reading, done by pattern.
    ///
    /// Runs on devices Apple Intelligence doesn't reach, and as the catch when
    /// a generation fails mid-trip. It is only willing to answer when the mail
    /// states exactly one amount, because choosing between two without
    /// understanding the sentence is guessing.
    private static func patternRead(_ message: MailMessage, tripID: UUID) -> DetectedExpense? {
        let source = message.readableText
        guard let amount = soleAmount(in: AmountScanner.candidates(in: source)) else { return nil }

        // Same hard rule as the model path: an email that describes money
        // arriving is not an expense, whoever read it.
        guard MoneyDirection.of(source) != .incoming else { return nil }

        return DetectedExpense(
            id: message.id,
            tripID: tripID,
            amount: amount,
            currencyCode: currencyCode(claimed: "", scanned: AmountScanner.candidates(in: source), source: source),
            payee: PayeeReader.payee(in: message.payeeSearchText, excluding: message.fromAddress),
            reference: AmountScanner.reference(in: source) ?? "",
            channel: channel(from: .unknown, message: message),
            receivedAt: message.receivedAt,
            sender: message.fromName,
            subject: message.subject,
            relevance: MerchantIndex.isOnlineShopping(source) ? .onlineOrder : .trip,
            confidence: .likely,
            status: .waiting,
            detectedAt: Date()
        )
    }
}

// MARK: - Merchants

/// The shops whose payments are real and aren't the trip's.
///
/// Only marketplaces and retail. Food delivery is deliberately absent: four
/// people ordering dinner to a hotel room on the third night is a group
/// expense by any reading, and filing it away as "not the trip" would hide the
/// most commonly split thing there is. Getting this wrong in either direction
/// is one tap to fix on the card — the bucket is a default, not a verdict.
enum MerchantIndex {
    private static let shopping = [
        "amazon", "flipkart", "myntra", "ajio", "meesho", "nykaa", "tatacliq",
        "snapdeal", "shein", "aliexpress", "ebay", "etsy", "asos", "zara.com",
        "apple store", "croma", "reliance digital", "vijay sales", "decathlon",
        "your order", "order confirmation", "order placed", "has been shipped",
        "out for delivery", "your package"
    ]

    static func isOnlineShopping(_ text: String) -> Bool {
        let lower = text.lowercased()
        return shopping.contains { lower.contains($0) }
    }
}
