//
//  UPI.swift
//  Equitrip
//

import Foundation

/// Building the one URL every UPI app on the phone already knows how to open.
///
/// NPCI's deep-link spec is the same whether the far end is Google Pay,
/// PhonePe or Paytm — each registers the bare `upi://` scheme, not its own —
/// so a single `upi://pay?...` link is enough to hand off to whichever one is
/// installed, or let iOS offer a chooser when more than one is.
enum UPILink {
    /// Nil when there's no VPA to pay — a blank query would still open an
    /// app, just to a payment screen with nothing filled in.
    static func payURL(vpa: String, payeeName: String, amount: Double, note: String) -> URL? {
        let trimmed = vpa.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        components.queryItems = [
            URLQueryItem(name: "pa", value: trimmed),
            URLQueryItem(name: "pn", value: payeeName),
            URLQueryItem(name: "am", value: String(format: "%.2f", amount)),
            URLQueryItem(name: "cu", value: "INR"),
            URLQueryItem(name: "tn", value: note),
        ]
        return components.url
    }

    /// A VPA reads as one once it has the `@bank` half — the loosest check
    /// that still catches "forgot the second half" without rejecting handles
    /// this app has never seen.
    static func looksValid(_ vpa: String) -> Bool {
        let trimmed = vpa.trimmingCharacters(in: .whitespaces)
        guard let at = trimmed.firstIndex(of: "@") else { return false }
        return at > trimmed.startIndex && trimmed.index(after: at) < trimmed.endIndex
    }
}
