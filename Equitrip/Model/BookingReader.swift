//
//  BookingReader.swift
//  Equitrip
//

import Foundation

/// Which model reads a booking PDF into bookings — chosen in Settings.
///
/// Only the booking import follows this. Equi and the Gmail readers stay on
/// Apple Intelligence whatever it says: mail is promised never to leave the
/// phone, and Equi's figures come from Swift either way. A Nugen model is the
/// one that was domain-aligned on Indian booking documents (IndiGo codes,
/// Rajdhani numbers, "3A, PNR confirmed") and it also reads on iPhones that
/// can't run Apple Intelligence. It reads in the cloud, which Settings says
/// plainly; Apple Intelligence stays one tap away there.
enum BookingReader: Codable, Hashable {
    case appleIntelligence
    /// A deployed Nugen aligned model, reached through the `nugen-reader`
    /// Supabase function. The name is kept so Settings and the import screen
    /// can say which model without a round trip.
    case nugen(id: String, name: String)

    /// The aligned model booking imports use until the user picks another.
    /// `nugen-reader` accepts this id even when Nugen's aligned-model listing
    /// leaves it out, so the default can't silently fall through to patterns.
    static let nugenDefault = BookingReader.nugen(id: defaultModelID, name: defaultModelName)

    private static let defaultModelID = "model_01m3gncr4m0jbnqf"
    /// Nugen's own name for it ("model_equitrip_ledger_assistant") is an
    /// internal slug, so the default gets a user-facing one whatever Nugen says.
    private static let defaultModelName = "Nugen Domain-Aligned"

    var label: String {
        switch self {
        case .appleIntelligence: "Apple Intelligence"
        case .nugen(let id, _) where id == Self.defaultModelID: Self.defaultModelName
        case .nugen(_, let name): name
        }
    }

    /// A Nugen reader is its model id. The saved name is only a label and can
    /// disagree with the live listing, which would otherwise show the chosen
    /// model twice in Settings with neither row ticked.
    static func == (lhs: BookingReader, rhs: BookingReader) -> Bool {
        switch (lhs, rhs) {
        case (.appleIntelligence, .appleIntelligence): true
        case (.nugen(let a, _), .nugen(let b, _)): a == b
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nugenModelID)
    }

    var nugenModelID: String? {
        if case .nugen(let id, _) = self { return id }
        return nil
    }
}
