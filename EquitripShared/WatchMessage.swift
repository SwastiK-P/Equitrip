//
//  WatchMessage.swift
//  EquitripShared
//

import Foundation

/// The whole conversation between the phone and the watch.
///
/// The watch never signs in and never talks to Supabase — it reads the same
/// flattened `EquitripSnapshot` the widgets do, and the one thing it can ask
/// the phone to *do* is answer a settlement request. Everything travels as
/// JSON `Data` under a single key, because WatchConnectivity only carries
/// property-list types and a hand-built dictionary per message is a second
/// schema that drifts from this one.
///
/// Compiled into the app and the watch app only; the widgets have no reason
/// to know the watch exists.
///
/// `nonisolated` throughout: both ends decode these inside WatchConnectivity's
/// delegate callbacks, off the main actor, and there is nothing here that
/// needs one.
nonisolated enum WatchCommand: Codable, Equatable {
    /// "Send me what you have." Answered from the shared container, so it
    /// works from a background launch before any trip has loaded.
    case requestSnapshot

    /// Confirm or decline an incoming "I paid you". Ids only — the phone
    /// re-checks the settlement against its own copy before acting, and never
    /// trusts the watch's idea of what is pending.
    case respondToSettlement(settlementID: UUID, tripID: UUID, confirm: Bool)
}

nonisolated enum WatchReply: Codable, Equatable {
    case snapshot(EquitripSnapshot)
    case accepted
    case rejected(reason: String)
}

nonisolated enum WatchWire {

    /// The one key every payload travels under.
    static let key = "payload"

    static func encode<T: Encodable>(_ value: T) -> [String: Any] {
        guard let data = try? JSONEncoder.snapshot.encode(value) else { return [:] }
        return [key: data]
    }

    static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) -> T? {
        guard let data = dictionary[key] as? Data else { return nil }
        return try? JSONDecoder.snapshot.decode(type, from: data)
    }
}
