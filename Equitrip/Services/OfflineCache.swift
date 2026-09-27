//
//  OfflineCache.swift
//  Equitrip
//

import Foundation

/// The last copy of this account's trips, notifications and profile that
/// the server sent, kept on the phone.
///
/// Postgres is still the record, and every launch still asks it first. This
/// is what the app shows while it waits, and what it keeps showing when there
/// is no answer. Without it, a phone that lost signal on the way to the
/// airport opened on a spinner, then an error, then nothing. That's the
/// moment somebody most needs to see the booking reference.
///
/// Files are kept per account, under the `auth.users` id, and deleted on
/// sign-out. A second account on the same phone must never open on the
/// first one's trips, the same rule `SupabaseRepository.profileID` follows.
enum OfflineCache {

    /// Who "you" were the last time the server said. `AuthService.bindIdentity`
    /// adopts this when the profile can't be fetched. Without it, an offline
    /// launch got a random id for "you", every "is this mine?" check failed,
    /// and each expense logged offline had a stranger's name on it.
    struct Identity: Codable {
        var profileID: UUID
        var name: String?
        var avatarAsset: String?
        var avatarURL: URL?
        var upiVPA: String?
    }

    enum Entry: String {
        case identity, trips, notifications, outbox
    }

    // MARK: - Reading

    static func load<Value: Decodable>(_ type: Value.Type, _ entry: Entry, account: UUID) -> Value? {
        guard let data = try? Data(contentsOf: url(for: entry, account: account)) else { return nil }
        // A shape that no longer decodes, after an update changed a model, is
        // treated as no cache. The next sync writes a fresh one.
        return try? decoder.decode(Value.self, from: data)
    }

    // MARK: - Writing

    /// Encodes now, on the caller's actor, so the value written is the one
    /// passed in. The disk write happens off the main thread.
    static func save<Value: Encodable>(_ value: Value, _ entry: Entry, account: UUID) {
        guard let data = try? encoder.encode(value) else { return }
        let target = url(for: entry, account: account)
        Task.detached(priority: .utility) {
            write(data, to: target)
        }
    }

    /// The same, but finished before it returns. For the outbox: a change
    /// the person was just told is saved has to be on disk before the app
    /// can be killed.
    static func saveNow<Value: Encodable>(_ value: Value, _ entry: Entry, account: UUID) {
        guard let data = try? encoder.encode(value) else { return }
        write(data, to: url(for: entry, account: account))
    }

    /// Everything kept for one account. Called on sign-out.
    static func wipe(account: UUID) {
        try? FileManager.default.removeItem(at: folder(for: account))
    }

    // MARK: - Files

    private nonisolated static func write(_ data: Data, to url: URL) {
        let folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // Readable after first unlock, not only while unlocked. Siri and the
        // watch can wake the app while the phone is locked, and they read
        // the same trips.
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private static func url(for entry: Entry, account: UUID) -> URL {
        folder(for: account).appendingPathComponent("\(entry.rawValue).v1.json")
    }

    private static func folder(for account: UUID) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
            .appendingPathComponent("Offline", isDirectory: true)
            .appendingPathComponent(account.uuidString, isDirectory: true)
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
}
