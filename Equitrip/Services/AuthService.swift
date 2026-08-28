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

    /// Display name from the signup metadata, falling back to the email.
    /// The signed-in address. Surfaced here so callers don't have to import
    /// the Auth module just to read one string off the session.
    var email: String? { session?.user.email }

    var displayName: String? {
        guard let user = session?.user else { return nil }
        if case let .string(name)? = user.userMetadata["full_name"], !name.isEmpty {
            return name
        }
        return user.email
    }

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

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
        forgetIdentity()
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
