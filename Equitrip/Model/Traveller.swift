//
//  Traveller.swift
//  Equitrip
//

import SwiftUI

struct Traveller: Identifiable, Hashable {
    let id: UUID
    let name: String
    let asset: String
    /// How this person is reached, and the thing that makes them the same
    /// person next time. A name is not an identity — two people type "Rohan"
    /// and get two Rohans, neither of whom can be told they owe anything.
    let email: String?
    /// Whether they already have an Equitrip account. False means invited:
    /// they're a real row on the trip and become an account when they sign up
    /// with the same address.
    let isRegistered: Bool
    /// A photograph they uploaded, which wins over `asset` when present.
    let avatarURL: URL?
    /// The VPA this person pays into, as they set it in their own Settings.
    /// Nil (not empty) means they haven't set one — the distinction that
    /// keeps a settle sheet from offering an editable field for someone
    /// else's payment details.
    let upiVPA: String?

    init(
        id: UUID = UUID(),
        name: String,
        asset: String,
        email: String? = nil,
        isRegistered: Bool = false,
        avatarURL: URL? = nil,
        upiVPA: String? = nil
    ) {
        self.id = id
        self.name = name
        self.asset = asset
        self.email = email
        self.isRegistered = isRegistered
        self.avatarURL = avatarURL
        self.upiVPA = upiVPA
    }

    var initial: String { String(name.prefix(1)) }

    // Memberwise, for the same reason as `ItineraryItem` — `id` alone hid
    // renames from SwiftUI, and "you" keeps one fixed id across the sign-in
    // that finally gives it a real name.

    static let ed = Traveller(name: "Ed", asset: "Avatar02")
    static let krishna = Traveller(name: "Krishna", asset: "Avatar05")
    static let mattew = Traveller(name: "Mattew", asset: "Avatar09")
    static let kim = Traveller(name: "Kim", asset: "Avatar14")
    /// Onboarding-only — shown before sign-in, so it needs a person who
    /// isn't "you". Nothing else references it by name.
    static let priya = Traveller(name: "Priya", asset: "Avatar01")

    /// The signed-in traveller.
    static var you: Traveller { CurrentUser.traveller }

    static var all: [Traveller] { [you, ed, krishna, mattew, kim] }

    /// Every avatar somebody can pick for themselves. Ordered, so the picker
    /// doesn't reshuffle between openings.
    static let avatars = (1...15).map { String(format: "Avatar%02d", $0) }

    /// The artwork to actually draw for a stored asset name.
    ///
    /// Profile rows outlive the artwork: rows written before this set hold
    /// names from the old memoji one — `MemojiChris` from the original schema
    /// default, `Memoji42` from the picker that replaced it — and `Image(_:)`
    /// draws *nothing* for a name the catalogue doesn't have, so those people
    /// would show up as an empty circle until they next opened the picker.
    /// Anything unrecognised is folded onto the new set instead, by name, so
    /// the same stored value picks the same face on every device.
    static func artwork(for asset: String) -> String {
        guard !avatars.contains(asset) else { return asset }
        return avatars[Int(stableHash(asset) % UInt64(avatars.count))]
    }

    /// Spelled out rather than `hashValue`, which is seeded per process and
    /// would hand the same person a different face on every launch.
    static func stableHash(_ text: String) -> UInt64 {
        text.unicodeScalars.reduce(into: UInt64(5381)) { total, scalar in
            total = total &* 33 &+ UInt64(scalar.value)
        }
    }
}

/// Who "you" are, app-wide.
///
/// The identity is a fixed UUID set once at launch, so every `participantIDs`
/// set, every avatar and every "is this mine?" check agrees — including across
/// trips created before the display name was known. Only the label changes
/// when the session resolves.
enum CurrentUser {
    private nonisolated(unsafe) static var displayName = "You"
    /// The avatar artwork behind the face. Overwritten by whichever one the
    /// user picks, and by whatever their profile row already said on sign-in.
    private nonisolated(unsafe) static var avatarAsset = "Avatar01"
    /// A photograph they chose, which wins over the avatar.
    private nonisolated(unsafe) static var avatarURL: URL?
    /// A random UUID until the Supabase profile resolves, so the app has an
    /// identity to work with offline or before sign-in finishes. Everything
    /// keyed off this — trip membership, message authorship, "who created
    /// this booking" — is worthless once a server is involved unless it's
    /// swapped for the real `profiles.id`, which `adoptID` does.
    private nonisolated(unsafe) static var identity = UUID()
    /// The signed-in address. Held so "you" is the same shape of traveller as
    /// everyone else — identified by email — rather than a special case.
    private nonisolated(unsafe) static var address: String?
    /// The VPA this account pays into, as loaded from `profiles.upi_id`.
    private nonisolated(unsafe) static var upiVPA: String?

    static var traveller: Traveller {
        Traveller(
            id: identity,
            name: displayName,
            asset: avatarAsset,
            email: address,
            isRegistered: true,
            avatarURL: avatarURL,
            upiVPA: upiVPA
        )
    }

    /// Records the face this account carries. Both together, always: an
    /// avatar picked after a photograph has to clear that photograph, or the
    /// photo keeps winning and the pick looks like it did nothing.
    static func adoptAvatar(asset: String, url: URL?) {
        avatarAsset = asset
        avatarURL = url
    }

    /// Records the VPA this account pays into, whether that's what the server
    /// already had on sign-in or what the user just typed into Settings.
    static func adoptUPI(_ vpa: String?) {
        let trimmed = vpa?.trimmingCharacters(in: .whitespaces)
        upiVPA = (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    /// Called once the session is restored. Takes the first name only — a
    /// participant chip is no place for someone's full legal name.
    static func adopt(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        if name.contains("@") { address = name.lowercased() }
        let base = name.contains("@") ? String(name.split(separator: "@")[0]) : name
        guard let first = base.split(separator: " ").first else { return }
        displayName = String(first).capitalized
    }

    /// Records the signed-in address, whatever the display name turned out to
    /// be. `adopt` only sees one when the account has no full name set.
    static func adoptEmail(_ email: String?) {
        guard let email, email.contains("@") else { return }
        address = email.lowercased()
    }

    /// Binds "you" to the real Supabase profile row. Must run before any trip
    /// data is read or synced — a mismatch here is why a chat message insert
    /// or an `is_trip_member` check would otherwise fail against the server
    /// even though everything looks right on screen.
    static func adoptID(_ id: UUID) {
        identity = id
    }

    /// Forgets who "you" are. Must run on every sign-out and sign-in: this is
    /// process-wide mutable state, so without it the next account inherits the
    /// previous one's identity and name, and every `isYou` check, participant
    /// set and message authorship silently answers for the wrong person.
    static func reset() {
        displayName = "You"
        identity = UUID()
        address = nil
        avatarAsset = "Avatar01"
        avatarURL = nil
        upiVPA = nil
    }

    static func isYou(_ name: String) -> Bool {
        name.caseInsensitiveCompare(displayName) == .orderedSame
    }
}
