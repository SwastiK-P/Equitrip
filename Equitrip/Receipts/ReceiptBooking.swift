//
//  ReceiptBooking.swift
//  Equitrip
//

import Foundation

/// A scanned receipt turned into a booking for the full editor.
///
/// Receipts open in the detailed editor rather than quick add: a receipt
/// carries a vendor, a category and a printed day and time, and quick add
/// has nowhere to show or correct any of them. Everything read is filled in;
/// the split is the review screen's: even, or exact shares worked out from
/// who had which line (`ReceiptItemSplit`).
extension ItineraryItem {

    /// When the receipt printed a date or a time, that's when it happened;
    /// whichever it didn't print is taken from now. `shares`, when given, are
    /// exact amounts that already add up to the total.
    init(scan: ReceiptScan, travellers: [Traveller], shares: [UUID: Double]? = nil) {
        let calendar = Calendar.current
        let merchant = scan.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let day = calendar.startOfDay(for: scan.date ?? now)
        let minute = scan.minuteOfDay
            ?? calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        // You're the one holding the receipt, so you paid for it.
        let payer = travellers.first { $0.id == Traveller.you.id }?.id

        self.init(
            title: merchant,
            vendor: merchant,
            kind: scan.kind == .other ? .activity : scan.kind,
            date: day,
            time: .at(minute / 60, minute % 60, on: day),
            cost: scan.amountPaid,
            split: .equal,
            participantIDs: Set(travellers.map(\.id)),
            paidByID: payer,
            paymentMethod: payer == nil ? nil : (scan.paymentMethod ?? AppSettings.defaultPaymentMethod)
        )

        if let shares, !shares.isEmpty {
            split = .custom
            customShares = shares
            // Custom shares are stored on participant rows, so whoever has
            // one has to be on the booking.
            participantIDs = Set(shares.keys)
        }
    }
}
