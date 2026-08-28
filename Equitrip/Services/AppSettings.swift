//
//  AppSettings.swift
//  Equitrip
//

import SwiftUI
import UIKit

/// The handful of preferences that outlive a screen.
///
/// Deliberately not `@AppStorage`: these are read from places that aren't
/// views — `TripDraft`'s default currency, the payment sheet's opening
/// guess — and a property wrapper that only works inside a `View` would mean
/// the setting existed on the settings screen and nowhere it mattered. That's
/// exactly what "make those settings work" was about: the rows were there, and
/// nothing downstream ever read them.
enum AppSettings {

    // MARK: - Currency

    private static let currencyKey = "settings.defaultCurrency"

    /// What a new trip starts in. Per-trip currency still wins — a group can
    /// run Goa in rupees and Bali in dollars — this is only the starting point.
    static var defaultCurrency: String {
        get { UserDefaults.standard.string(forKey: currencyKey) ?? "INR" }
        set { UserDefaults.standard.set(newValue, forKey: currencyKey) }
    }

    // MARK: - Paying

    private static let methodKey = "settings.defaultPaymentMethod"

    /// Pre-selected when somebody records a payment. Most groups pay the same
    /// way most of the time, and the alternative was UPI hard-coded in the
    /// payment sheet regardless of where anybody was.
    static var defaultPaymentMethod: PaymentMethod {
        get {
            UserDefaults.standard.string(forKey: methodKey)
                .flatMap(PaymentMethod.init(rawValue:)) ?? .upi
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: methodKey) }
    }
}

// MARK: - Ledger export

/// The whole ledger as a spreadsheet.
///
/// CSV rather than a PDF: the reason somebody exports a group ledger is to
/// argue with it in a spreadsheet, or to paste it into whatever the group
/// already uses. A rendered document is the wrong shape for both.
enum LedgerExport {

    /// Writes every booking on every trip to a file, and hands back its URL.
    ///
    /// Returns nil only when the file can't be written — an account with no
    /// trips still gets a valid file with nothing but a header row, which is a
    /// truthful export rather than a silent failure.
    static func write(_ trips: [Trip]) -> URL? {
        var rows = [
            "Trip,Date,Booking,Category,Vendor,Cost,Currency,Split,Paid by,Method,Your share"
        ]

        for trip in trips.sorted(by: { $0.startDate < $1.startDate }) {
            for item in trip.items.sorted(by: Trip.chronological) {
                rows.append(
                    [
                        trip.title,
                        DateFormatter.cached("yyyy-MM-dd").string(from: item.date),
                        item.title,
                        item.kind.label,
                        item.vendor,
                        String(format: "%.2f", item.cost),
                        trip.currencyCode,
                        item.split.label,
                        item.paidByID.flatMap(trip.traveller)?.name ?? "",
                        item.paymentMethod?.label ?? "",
                        String(format: "%.2f", trip.share(of: item, for: Traveller.you.id))
                    ]
                    .map(escape)
                    .joined(separator: ",")
                )
            }
        }

        let name = "Equitrip-ledger-\(DateFormatter.cached("yyyy-MM-dd").string(from: Date())).csv"
        let url = URL.temporaryDirectory.appending(path: name)

        do {
            try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// A booking called `Dinner, Anjuna` is one field, not two — and a vendor
    /// with a quote in its name shouldn't break every column after it.
    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

// MARK: - Share sheet

/// `UIActivityViewController`, for the things `ShareLink` can't do.
///
/// `ShareLink` needs its payload up front, and the ledger file shouldn't be
/// written on every body pass of the settings screen just so a button has
/// something to point at. This is presented once, after the export actually
/// runs.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Lets a written file drive `sheet(item:)`, which needs identity.
struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}
