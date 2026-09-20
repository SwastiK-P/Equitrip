//
//  ReceiptGlance.swift
//  Equitrip
//

import FoundationModels
import UIKit

// MARK: - Schema

/// What the on-device model is asked about the picture itself.
///
/// One choice from a closed list, and nothing else: no description, no
/// amounts, no sentence to show anyone. The words people see when a picture
/// is turned down are written below, in `PictureKind.refusal`.
@Generable(description: "What one picture mainly shows")
private struct PictureReading {
    @Guide(description: "What the picture mainly shows.")
    var shows: PictureShows
}

@Generable
private enum PictureShows {
    case printedReceipt
    case invoice
    case paymentConfirmation
    case bookingOrTicket
    case handwrittenBill
    case menu
    case advertisement
    case otherText
    case photograph
}

// MARK: - Verdict

/// What a picture turned out to be, as far as a receipt reader cares.
enum PictureKind: Equatable {
    /// A receipt, bill, invoice, payment screen, ticket or handwritten bill:
    /// something that records money already spent.
    case receipt
    case menu
    case advert
    case otherText
    case photo

    var isReceipt: Bool { self == .receipt }

    /// Why the picture was set aside, in the app's words. Worded as a
    /// judgement that can be wrong, because the reading screen offers to read
    /// it anyway.
    var refusal: String {
        switch self {
        case .receipt:
            ""
        case .menu:
            "That looks like a menu: prices for things, not a bill for them. The receipt is what you're handed after paying."
        case .advert:
            "That looks like an ad or an offer. Its prices aren't something anyone paid."
        case .otherText:
            "That doesn't look like a receipt or a bill."
        case .photo:
            "That looks like a photo rather than a receipt. Pick the picture of the bill, or scan the paper."
        }
    }
}

// MARK: - Glance

/// One look at the picture itself: is this a receipt at all?
///
/// Everything else in the pipeline reads *text*, and text can't tell a bill
/// from an offer poster. "₹250 OFF on purchase of ₹999" has two prices on it,
/// and a parser that finds prices will find those. The on-device model, shown
/// the image, can see a coupon, a menu or a holiday photo for what it is.
///
/// It is asked only when the arithmetic hasn't already answered. A receipt
/// whose items and charges come to its printed total is a receipt whatever
/// anyone thinks it looks like, so `ReceiptReader` only glances when the
/// numbers don't settle it. The model's answer can't overrule them either, and
/// the reading screen still offers to read the picture anyway.
///
/// Apple Intelligence on this device, never Private Cloud Compute: receipts
/// are read here and nowhere else. With no model, or a model that can't see
/// images, or one that takes too long, the answer is nil and nothing changes.
@MainActor
enum ReceiptGlance {

    static var isAvailable: Bool {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return false }
        return model.capabilities.contains(.vision)
    }

    private static let instructions = """
        You look at one picture that someone chose to log as an expense, and \
        say what it mainly shows.

        - printedReceipt: a till receipt or bill on paper, from a shop, \
        restaurant, bar, hotel or taxi.
        - invoice: a bill or tax invoice as a document or on a screen.
        - paymentConfirmation: a phone screen saying a payment or order went \
        through, from a bank, UPI, card, food delivery or ride app.
        - bookingOrTicket: a hotel, flight, train, bus or event booking or ticket.
        - handwrittenBill: a bill written by hand, with prices.
        - menu: a menu or price list, for things not yet bought.
        - advertisement: an ad, offer, coupon, voucher or sale poster.
        - otherText: any other text, such as a message, note, form, \
        prescription or article.
        - photograph: people, places, food or things, with no bill in view.
        """

    /// Long enough for the vision model's first load; short enough that a
    /// stalled answer never holds up a receipt.
    private static let patience: Duration = .seconds(6)

    /// What the picture shows, or nil when the model couldn't say.
    static func kind(of page: UIImage) async -> PictureKind? {
        guard isAvailable,
              // The model sees a small picture; the page is up to 3200px.
              let image = ReceiptImagePrep.upright(page, maxDimension: 1024) else { return nil }

        let look = Task { await ask(about: image) }
        let deadline = Task {
            try await Task.sleep(for: patience)
            look.cancel()
        }
        let kind = await look.value
        deadline.cancel()
        return kind
    }

    private static func ask(about image: CGImage) async -> PictureKind? {
        do {
            let session = LanguageModelSession(instructions: instructions)
            let reading = try await session.respond(
                generating: PictureReading.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "What does this picture mainly show?"
                Attachment(image)
            }.content
            return kind(for: reading.shows)
        } catch {
            // Unavailable, cancelled by the deadline, or refused by the
            // guardrails: no opinion, which leaves the rules to decide.
            return nil
        }
    }

    /// Handwritten bills count as receipts: a small shop's bill often is
    /// one, and the rules decide whether its prices can be read.
    private static func kind(for shows: PictureShows) -> PictureKind {
        switch shows {
        case .printedReceipt, .invoice, .paymentConfirmation, .bookingOrTicket, .handwrittenBill: .receipt
        case .menu: .menu
        case .advertisement: .advert
        case .otherText: .otherText
        case .photograph: .photo
        }
    }
}
