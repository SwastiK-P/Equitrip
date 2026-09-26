//
//  AuthService.swift
//  Equitrip
//

import Foundation
import Supabase

/// Wraps Supabase auth so views never touch the SDK directly.
@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    let client: SupabaseClient

    /// Non-nil once signed in. The SDK persists and refreshes this across
    /// launches, so `restore()` is enough to skip the auth screens.
    private(set) var session: Session?

    var isSignedIn: Bool { session != nil }

    /// The profile row's name, filled in by `bindIdentity`.
    private(set) var profileName: String?

    /// Signup metadata first, then the profile row, then the email.
    var displayName: String? {
        guard let user = session?.user else { return nil }
        if case let .string(name)? = user.userMetadata["full_name"], !name.isEmpty {
            return name
        }
        if let profileName, !profileName.isEmpty { return profileName }
        return user.email
    }

    /// The signed-in address. Surfaced here so callers don't have to import
    /// the Auth module just to read one string off the session.
    var email: String? { session?.user.email }

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.publishableKey
        )
    }

    // MARK: - Actions

    func signIn(email: String, password: String) async throws {
        // Clear first, not after. A failed sign-in must not leave the previous
        // account's identity in place either.
        forgetIdentity()
        session = try await client.auth.signIn(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }

    /// Returns `false` when the project requires email confirmation — the
    /// account exists but there's no session yet.
    @discardableResult
    func signUp(name: String, email: String, password: String) async throws -> Bool {
        forgetIdentity()
        let response = try await client.auth.signUp(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            data: ["full_name": .string(name.trimmingCharacters(in: .whitespaces))]
        )
        session = response.session
        return response.session != nil
    }

    /// Restores a persisted session on launch. Silent by design — a missing or
    /// expired session simply means "show the auth screens".
    func restore() async {
        session = try? await client.auth.session
    }

    /// "You" only means something once we know who that is on both sides:
    /// the display name for the UI, and the real `profiles.id` for anything
    /// that talks to Supabase. Every participant chip, message and
    /// `is_trip_member` check downstream reads this, so it has to finish
    /// before Home appears — a chat message sent under the wrong id fails
    /// its foreign key silently, which is a much worse debugging experience
    /// than a brief wait there.
    ///
    /// Lives here rather than in `ContentView` because it is not only the
    /// launch screen that needs it: a watch answering a settlement can wake
    /// the app in the background with no view on screen at all, and the
    /// answer has to go out under the right id all the same.
    func bindIdentity() async {
        CurrentUser.adopt(displayName)
        CurrentUser.adoptEmail(email)
        if let id = try? await SupabaseRepository.shared.resolveProfile() {
            CurrentUser.adoptID(id)
            profileName = SupabaseRepository.shared.currentName
            CurrentUser.adopt(displayName)
            if let face = SupabaseRepository.shared.currentAvatar {
                CurrentUser.adoptAvatar(asset: Traveller.artwork(for: face.asset), url: face.url)
            }
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
        profileName = nil
        forgetIdentity()
        // The widgets and the watch both hold a copy of the last account's
        // balance, and neither can find out on its own that it's gone.
        WidgetPublisher.clear()
    }

    /// Drops every trace of who was signed in.
    ///
    /// Both of these are process-wide singletons, and leaving either behind is
    /// what let a second account sign in on top of the first and inherit its
    /// trips, its membership and its organiser role.
    private func forgetIdentity() {
        SupabaseRepository.shared.forgetProfile()
        CurrentUser.reset()
    }

    // MARK: - Errors

    /// Supabase surfaces these as terse API strings; map the common ones to
    /// something a person can act on.
    static func message(for error: Error) -> String {
        if let authError = error as? AuthError {
            let raw = authError.localizedDescription.lowercased()
            if raw.contains("invalid login credentials") {
                return "That email and password don't match."
            }
            if raw.contains("already registered") || raw.contains("already been registered") {
                return "That email already has an account. Try signing in."
            }
            if raw.contains("email not confirmed") {
                return "Confirm your email first — check your inbox."
            }
            if raw.contains("password") && raw.contains("least") {
                return "Password is too short."
            }
            return authError.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "You're offline. Check your connection."
            case .timedOut:
                return "That took too long. Try again."
            default:
                return "Couldn't reach the server. Try again."
            }
        }

        return error.localizedDescription
    }
}
