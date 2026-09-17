//
//  Money.swift
//  Equitrip
//

import SwiftUI

// MARK: - Money

/// Currency lives on the trip, not the app, so a group can run a Goa trip in
/// rupees and a Bali trip in dollars without converting anything.
enum Money {
    static func format(_ amount: Double, code: String, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = amount.rounded() == amount ? 0 : 2
        formatter.locale = Locale(identifier: code == "INR" ? "en_IN" : "en_US")

        let magnitude = formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
        guard signed else { return magnitude }
        if amount > 0 { return "+" + magnitude }
        if amount < 0 { return "−" + magnitude }
        return magnitude
    }

    /// The bare number, for a text field somebody is about to edit.
    /// `480` rather than `480.0`, `479.5` rather than `479.50` — a grouping
    /// separator or a trailing zero in a `.decimalPad` field is one more thing
    /// to delete before typing.
    static func plainAmount(_ amount: Double) -> String {
        amount.rounded() == amount
            ? String(Int(amount.rounded()))
            : String(format: "%.2f", amount)
    }

    static func symbol(for code: String) -> String {
        switch code.uppercased() {
        case "INR": "₹"
        case "USD": "$"
        case "EUR": "€"
        case "GBP": "£"
        case "JPY": "¥"
        case "AED": "د.إ"
        case "THB": "฿"
        case "SGD": "S$"
        default: code.uppercased()
        }
    }

    static let common = ["INR", "USD", "EUR", "GBP", "AED", "THB", "SGD", "JPY"]
}
