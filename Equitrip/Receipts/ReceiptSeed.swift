//
//  ReceiptSeed.swift
//  Equitrip
//

import UIKit

/// A scanned receipt turned into what the quick-add sheet already accepts.
///
/// The scanner has no screen of its own: people log expenses in one place,
/// and a receipt only saves them the typing. So everything read — merchant,
/// total, when, how it was paid, the category — becomes a `Seed`, and the
/// split and participants are chosen on the same sheet as any other expense.
extension QuickAddSheet.Seed {

    init(scan: ReceiptScan, pages: [UIImage], day: Date, tripCurrency: String) {
        let merchant = scan.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        // The printed total is the figure; the parts only stand in when the
        // receipt never printed one.
        let amount = scan.total ?? (scan.itemsTotal + scan.chargesTotal)

        var paidAt = Date()
        if let minute = scan.minuteOfDay {
            paidAt = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: day) ?? paidAt
        }

        self.init(
            title: merchant,
            vendor: merchant,
            amount: (amount * 100).rounded() / 100,
            paidAt: paidAt,
            paymentMethod: scan.paymentMethod ?? AppSettings.defaultPaymentMethod,
            provenance: Self.provenance(for: scan, tripCurrency: tripCurrency),
            kind: scan.kind == .other ? nil : scan.kind,
            receiptPages: pages
        )
    }

    /// One line saying what was read and whether it checked out, so a total
    /// that didn't add up is questioned before it's saved.
    private static func provenance(for scan: ReceiptScan, tripCurrency: String) -> String {
        var parts = ["Read from receipt"]
        if !scan.lines.isEmpty {
            parts.append(scan.lines.count == 1 ? "1 item" : "\(scan.lines.count) items")
        }
        switch scan.check {
        case .balanced, .rounded: parts.append("adds up")
        case .unaccounted, .noTotal: parts.append("check the total")
        case .noItems: break
        }
        // Never converted: a rate would be a number the receipt didn't print.
        if let printed = scan.currencyCode, printed.uppercased() != tripCurrency.uppercased() {
            parts.append("printed in \(printed.uppercased()), not converted")
        } else if let lastFour = scan.cardLastFour {
            parts.append("card ··\(lastFour)")
        }
        return parts.joined(separator: " · ")
    }
}
