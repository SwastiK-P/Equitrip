//
//  TravellerDirectory.swift
//  Equitrip
//

import Foundation
import Supabase

/// Turning an email address into a person.
///
/// Adding someone to a trip used to mean typing their name, which meant the
/// group's ledger was keyed on a string somebody remembered how to spell.
/// "Rohan" and "rohan" were two people; neither could be told they owed
/// anything, and neither became an account when the real Rohan signed up.
///
/// An address fixes all three. It resolves to an existing account when there is
/// one — so the name is fetched, not typed — and to a placeholder profile when
/// there isn't, which the same address claims later at signup.
///
/// The lookup deliberately can't be used to browse: it matches one exact
/// address and answers with a person, never with an address. See
/// `0004_traveller_directory.sql`, which is where the enforcement actually is.
@MainActor
enum TravellerDirectory {

    /// What an address turned out to be.
    enum Match: Equatable {
        /// Already on Equitrip. Their name and avatar are theirs, not a guess.
        case registered(Traveller)
        /// Not on Equitrip yet. Still a real profile on the trip; they claim it
        /// by signing up with this address.
        case invited(Traveller)
        /// The address doesn't lead anywhere yet and nothing has been created.
        case unknown

        var traveller: Traveller? {
            switch self {
            case .registered(let person), .invited(let person): person
            case .unknown: nil
            }
        }
    }

    enum DirectoryError: LocalizedError {
        case malformed
        case directoryUnavailable
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .malformed: "That doesn't look like an email address."
            case .directoryUnavailable:
                "Looking people up isn't set up on this project yet. Run the 0004 migration in Supabase."
            case .failed(let message): message
            }
        }
    }

    private static var client: SupabaseClient { AuthService.shared.client }

    /// Deliberately permissive. Rejecting valid-but-unusual addresses is worse
    /// than letting one through — the lookup simply finds nobody.
    static func isPlausible(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5, !trimmed.contains(" ") else { return false }
        let parts = trimmed.components(separatedBy: "@")
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        return parts[1].contains(".") && !parts[1].hasPrefix(".") && !parts[1].hasSuffix(".")
    }

    static func normalise(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Lookup

    /// Who, if anyone, this address already is. Creates nothing.
    static func lookUp(_ email: String) async throws -> Match {
        let address = normalise(email)
        guard isPlausible(address) else { throw DirectoryError.malformed }

        let rows: [DirectoryRow] = try await call("find_traveller", ["p_email": address])
        guard let row = rows.first else { return .unknown }
        return row.match(email: address)
    }

    /// Who this address is, creating a placeholder profile if it's nobody yet.
    ///
    /// Called when someone is actually added to a trip rather than while
    /// they're being typed, so an abandoned half-typed address never leaves a
    /// row behind.
    static func claim(_ email: String) async throws -> Match {
        let address = normalise(email)
        guard isPlausible(address) else { throw DirectoryError.malformed }

        let rows: [DirectoryRow] = try await call(
            "invite_traveller",
            ["p_email": address, "p_avatar": suggestedAvatar(for: address)]
        )
        guard let row = rows.first else { throw DirectoryError.failed("Couldn't add that address.") }
        return row.match(email: address)
    }

    /// Resolves several addresses at once, keeping the order they were added
    /// in so the memoji don't reshuffle between screens.
    static func claimAll(_ emails: [String]) async -> [Traveller] {
        var people: [Traveller] = []
        for email in emails {
            guard let person = try? await claim(email).traveller else { continue }
            guard !people.contains(where: { $0.id == person.id }) else { continue }
            people.append(person)
        }
        return people
    }

    // MARK: - Plumbing

    private static func call<T: Decodable>(_ function: String, _ params: [String: String]) async throws -> T {
        do {
            return try await client.rpc(function, params: params).execute().value
        } catch {
            // A missing function is the one failure worth naming precisely:
            // it means the migration hasn't been run, and no amount of
            // retrying will fix it.
            let text = "\(error)".lowercased()
            if text.contains("pgrst202") || text.contains("could not find the function")
                || text.contains("does not exist") {
                throw DirectoryError.directoryUnavailable
            }
            throw DirectoryError.failed(AuthService.message(for: error))
        }
    }

    /// Memoji are assigned from the address so the same person keeps the same
    /// face across trips and devices, rather than from their position in a
    /// list, which changed every time somebody was removed.
    private static func suggestedAvatar(for email: String) -> String {
        let assets = Traveller.all.map(\.asset)
        let hash = email.unicodeScalars.reduce(into: UInt64(5381)) { total, scalar in
            total = total &* 33 &+ UInt64(scalar.value)
        }
        return assets[Int(hash % UInt64(assets.count))]
    }
}

private struct DirectoryRow: Decodable {
    let id: UUID
    let display_name: String
    let avatar_asset: String
    let is_registered: Bool

    func match(email: String) -> TravellerDirectory.Match {
        let person = Traveller(
            id: id,
            name: display_name,
            asset: avatar_asset,
            email: email,
            isRegistered: is_registered
        )
        return is_registered ? .registered(person) : .invited(person)
    }
}
