//
//  PaymentMethod.swift
//  Equitrip
//

import SwiftUI

// MARK: - Paying

/// How a booking was actually settled with the vendor.
///
/// Separate from the split, and easy to confuse with it: the split says whose
/// cost this is, the method says how the money left somebody's hands. Only
/// the second one can produce a receipt, which is why `isOnline` exists — a
/// cash dinner has nothing to photograph, an online booking has a
/// confirmation everybody else on the item will eventually want to see.
enum PaymentMethod: String, CaseIterable, Identifiable, Codable {
    case cash, upi, card, transfer, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cash: "Cash"
        case .upi: "UPI"
        case .card: "Card"
        case .transfer: "Bank transfer"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cash: "banknote"
        case .upi: "indianrupeesign.circle"
        case .card: "creditcard"
        case .transfer: "building.columns"
        case .other: "ellipsis.circle"
        }
    }

    /// Whether there's a confirmation worth attaching. Cash leaves no trail
    /// worth photographing; everything else does.
    var isOnline: Bool { self != .cash }
}
