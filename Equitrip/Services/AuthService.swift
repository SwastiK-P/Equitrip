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

    /// The `auth.users` id behind the session, which is what everything kept
    /// on the phone is filed under — see `OfflineCache`.
    var accountID: UUID? { session?.user.id }

    /// The signed-in address. Surfaced here so callers don't have to import
    /// the Auth module just to read one string off the session.
    var email: String? { session?.user.email }

    private init() {
        var session = URLSession.shared
        #if DEBUG
        if SimulatedOffline.isOn {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [SimulatedOffline.self]
            session = URLSession(configuration: configuration)
        }
        #endif
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.publishableKey,
            options: SupabaseClientOptions(global: .init(session: session))
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
    ///
    /// Except offline. An access token lasts an hour, so after a night's sleep
    /// the SDK has to refresh it before it will hand it over, and with no
    /// network that fails. That sent everybody who opened the app on a plane
    /// back to onboarding, signed out, with their trips out of reach. The
    /// stored session is still theirs, so it's used as is. The SDK refreshes
    /// it on the first request after the connection comes back, and signs
    /// them out properly then if the refresh token has been revoked.
    func restore() async {
        do {
            session = try await client.auth.session
        } catch {
            session = NetworkMonitor.isConnectivity(error) ? client.auth.currentSession : nil
        }
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
    ///
    /// Offline, "who you are" comes from `OfflineCache` instead: the last
    /// profile the server confirmed for this login. The outbox is opened for
    /// the same account here too, so writes queued last time are ready to
    /// send before the first screen can add to them.
    func bindIdentity() async {
        CurrentUser.adopt(displayName)
        CurrentUser.adoptEmail(email)
        guard let account = session?.user.id else { return }
        OfflineOutbox.shared.open(account: account)

        let repository = SupabaseRepository.shared
        if let id = try? await repository.resolveProfile() {
            if let identity = repository.cachedIdentity {
                OfflineCache.save(identity, .identity, account: account)
            }
            adopt(id)
        } else if let saved = OfflineCache.load(OfflineCache.Identity.self, .identity, account: account) {
            repository.adoptCachedProfile(saved, owner: account)
            CurrentUser.adoptUPI(saved.upiVPA)
            adopt(saved.profileID)
        }
    }

    private func adopt(_ profileID: UUID) {
        CurrentUser.adoptID(profileID)
        profileName = SupabaseRepository.shared.currentName
        CurrentUser.adopt(displayName)
        if let face = SupabaseRepository.shared.currentAvatar {
            CurrentUser.adoptAvatar(asset: Traveller.artwork(for: face.asset), url: face.url)
        }
    }

    func signOut() async {
        let account = session?.user.id
        OfflineOutbox.shared.close()
        try? await client.auth.signOut()
        session = nil
        // The phone's copy of this account goes with it, queued changes
        // included. Leaving them would open the next account on these trips.
        // After `session` is cleared, so a cache write already scheduled
        // finds nobody signed in and doesn't put the files back.
        if let account { OfflineCache.wipe(account: account) }
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
