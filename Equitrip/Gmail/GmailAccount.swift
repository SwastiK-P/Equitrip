//
//  GmailAccount.swift
//  Equitrip
//

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Security
import UIKit

// MARK: - Keychain

/// One small box for the refresh token.
///
/// `UserDefaults` would have been three lines shorter and wrong: a refresh
/// token is a standing key to somebody's mailbox, and the defaults plist is
/// readable from a backup. `kSecAttrAccessibleAfterFirstUnlock` rather than
/// `WhenUnlocked` because the sync runs on a background refresh, which can
/// happen with the phone in a pocket.
enum GmailKeychain {
    private static let service = "app.equitrip.gmail"

    /// Returns the status rather than swallowing it.
    ///
    /// `SecItemAdd` failing is rare and, when it happens, total: the token is
    /// gone, the connection silently doesn't exist, and the screen goes back
    /// to offering the button that was just pressed. The usual cause on a
    /// development build is `errSecMissingEntitlement` (-34018), which means
    /// the app was signed without a keychain access group — the fix is a
    /// signing team on the target, not anything in this file.
    @discardableResult
    static func store(_ value: String, for key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var insert = query
        insert[kSecValueData as String] = Data(value.utf8)
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(insert as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ] as CFDictionary)
    }
}

// MARK: - Errors

enum GmailError: LocalizedError {
    case notConfigured
    case cancelled
    case noRefreshToken
    case authFailed(String)
    case http(Int, String)
    case decoding
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Gmail isn't set up in this build yet."
        case .cancelled:
            "Sign-in was cancelled."
        case .noRefreshToken:
            "Google didn't return a lasting permission. Try connecting again."
        case .authFailed(let detail):
            detail
        case .http(let code, let detail):
            code == 401 || code == 403
                ? "Gmail turned the request down. Reconnect the account."
                : "Gmail couldn't be reached (\(code)). \(detail)"
        case .decoding:
            "Gmail replied with something this app couldn't read."
        case .keychain(let status):
            "This device wouldn't store the Gmail permission (keychain error \(status)). If this is a development build, set a signing team on the target and try again."
        }
    }
}

// MARK: - Account

/// The connected mailbox: signing in, staying signed in, and signing out.
///
/// Deliberately the only thing in the app that knows an access token exists.
/// Everything downstream asks for `authorizedToken()` and gets a valid one or
/// an error — refreshing sixty seconds before expiry rather than after it,
/// because a token that expires mid-sync produces a 401 that reads to the user
/// as "Gmail disconnected itself".
@MainActor
@Observable
final class GmailAccount: NSObject {

    static let shared = GmailAccount()

    private static let refreshKey = "refreshToken"
    private static let emailKey = "settings.gmail.address"
    private static let enabledKey = "settings.gmail.enabled"

    /// Which mailbox is connected. Nil means nobody is.
    private(set) var address: String?
    private(set) var isConnecting = false
    private(set) var lastError: String?

    /// Connected but paused. Kept apart from disconnecting, because revoking
    /// the token means going through Google's consent screen again to come
    /// back — a switch that stops the reading should not cost that.
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    private var accessToken: String?
    private var accessTokenExpiry: Date?
    private var webSession: ASWebAuthenticationSession?

    /// The token is the connection. The address is a label on it.
    ///
    /// These were one condition, and that was the bug: Google's profile call
    /// failing — a blip, a scope Google hasn't propagated yet — left a
    /// perfectly good refresh token in the keychain and the screen still
    /// offering to connect, with nothing said about why. A mailbox whose
    /// address we couldn't read is still a connected mailbox.
    var isConnected: Bool { GmailKeychain.read(Self.refreshKey) != nil }
    /// What the sync loop checks: connected *and* switched on.
    var isActive: Bool { isConnected && isEnabled }

    private override init() {
        address = UserDefaults.standard.string(forKey: Self.emailKey)
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        super.init()

        // A stored address with no token left in the keychain — an app
        // reinstall, usually — is a connection that only looks like one.
        if address != nil, !isConnected {
            address = nil
            UserDefaults.standard.removeObject(forKey: Self.emailKey)
        }
    }

    // MARK: - Connecting

    func connect() async {
        guard GmailConfig.isConfigured else {
            lastError = GmailError.notConfigured.errorDescription
            return
        }
        guard !isConnecting else { return }

        isConnecting = true
        lastError = nil
        defer { isConnecting = false }

        do {
            let verifier = Self.randomVerifier()
            let code = try await authorize(challenge: Self.challenge(for: verifier))
            let token = try await exchange(code: code, verifier: verifier)

            guard let refresh = token.refreshToken else { throw GmailError.noRefreshToken }

            let status = GmailKeychain.store(refresh, for: Self.refreshKey)
            // Read it back rather than trusting the status. Both have to hold:
            // a write that reports success and reads back empty is the same
            // broken connection as one that reports failure.
            guard status == errSecSuccess, GmailKeychain.read(Self.refreshKey) == refresh else {
                throw GmailError.keychain(status)
            }

            accessToken = token.accessToken
            accessTokenExpiry = Date().addingTimeInterval(token.expiresIn)
            isEnabled = true

            // Cosmetic, and allowed to fail. The connection is already real by
            // this point; if Google won't say which mailbox it is, the screen
            // says "Connected" instead of the address and everything else
            // works exactly the same.
            if let found = try? await fetchAddress(using: token.accessToken) {
                address = found
                UserDefaults.standard.set(found, forKey: Self.emailKey)
            }
        } catch GmailError.cancelled {
            // Backing out of the consent screen is an answer, not a fault.
        } catch {
            lastError = (error as? GmailError)?.errorDescription ?? error.localizedDescription
        }
    }

    func disconnect() async {
        if let refresh = GmailKeychain.read(Self.refreshKey) {
            // Best effort: the local token is going regardless, and leaving
            // Google's copy alive would keep the app in the account's
            // third-party list forever.
            var request = URLRequest(url: GmailConfig.revokeEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data("token=\(refresh)".utf8)
            _ = try? await URLSession.shared.data(for: request)
        }

        GmailKeychain.delete(Self.refreshKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        address = nil
        accessToken = nil
        accessTokenExpiry = nil
        lastError = nil
    }

    // MARK: - Tokens

    /// A token good for the next minute at least.
    func authorizedToken() async throws -> String {
        if let accessToken, let expiry = accessTokenExpiry, expiry.timeIntervalSinceNow > 60 {
            return accessToken
        }
        guard let refresh = GmailKeychain.read(Self.refreshKey) else {
            throw GmailError.noRefreshToken
        }

        let token = try await exchange(refreshToken: refresh)
        accessToken = token.accessToken
        accessTokenExpiry = Date().addingTimeInterval(token.expiresIn)
        return token.accessToken
    }

    /// Google has stopped honouring the refresh token — password change,
    /// consent withdrawn, six months idle. The connection is over; saying so
    /// is better than retrying every launch and failing quietly.
    func invalidate(reason: String) {
        GmailKeychain.delete(Self.refreshKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        address = nil
        accessToken = nil
        accessTokenExpiry = nil
        lastError = reason
    }

    // MARK: - OAuth plumbing

    private func authorize(challenge: String) async throws -> String {
        var components = URLComponents(url: GmailConfig.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "client_id", value: GmailConfig.clientID),
            .init(name: "redirect_uri", value: GmailConfig.redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: "\(GmailConfig.scope) email"),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            // Without both of these Google hands back an access token and no
            // refresh token, and the connection lasts an hour.
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent")
        ]

        guard let url = components.url else { throw GmailError.notConfigured }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: GmailConfig.redirectScheme
            ) { callback, error in
                if let error {
                    let cancelled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                    continuation.resume(throwing: cancelled ? GmailError.cancelled : GmailError.authFailed(error.localizedDescription))
                    return
                }
                guard let callback,
                      let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems
                else {
                    continuation.resume(throwing: GmailError.authFailed("Google's reply was empty."))
                    return
                }
                if let denial = items.first(where: { $0.name == "error" })?.value {
                    continuation.resume(throwing: denial == "access_denied"
                        ? GmailError.cancelled
                        : GmailError.authFailed(denial))
                    return
                }
                guard let code = items.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GmailError.authFailed("No authorisation code came back."))
                    return
                }
                continuation.resume(returning: code)
            }

            session.presentationContextProvider = self
            // A shared cookie jar would silently reuse whichever Google account
            // Safari is already signed into, which is the wrong one as often
            // as it's the right one.
            session.prefersEphemeralWebBrowserSession = true
            webSession = session
            session.start()
        }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: TimeInterval

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }

    private func exchange(code: String, verifier: String) async throws -> TokenResponse {
        try await postToken([
            "client_id": GmailConfig.clientID,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": GmailConfig.redirectURI
        ])
    }

    private func exchange(refreshToken: String) async throws -> TokenResponse {
        do {
            return try await postToken([
                "client_id": GmailConfig.clientID,
                "refresh_token": refreshToken,
                "grant_type": "refresh_token"
            ])
        } catch GmailError.http(let code, _) where code == 400 || code == 401 {
            invalidate(reason: "Google ended the Gmail connection. Connect it again to keep detecting expenses.")
            throw GmailError.noRefreshToken
        }
    }

    private func postToken(_ fields: [String: String]) async throws -> TokenResponse {
        var request = URLRequest(url: GmailConfig.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(
            fields
                .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $0.value)" }
                .joined(separator: "&")
                .utf8
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw GmailError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        guard let token = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
            throw GmailError.decoding
        }
        return token
    }

    /// Which mailbox this is. Shown in settings so a second Google account
    /// signed in by accident is visible rather than a mystery.
    private func fetchAddress(using token: String) async throws -> String? {
        var request = URLRequest(url: URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/profile")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw GmailError.http(status, String(data: data.prefix(200), encoding: .utf8) ?? "")
        }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["emailAddress"] as? String
    }

    // MARK: - PKCE

    private static func randomVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URL(Data(bytes))
    }

    private static func challenge(for verifier: String) -> String {
        base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension GmailAccount: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first

            guard let scene else {
                // Nothing on screen to present over. Can't happen from a
                // button tap, and an empty anchor is the only honest answer.
                return ASPresentationAnchor(frame: .zero)
            }
            return scene.keyWindow ?? ASPresentationAnchor(windowScene: scene)
        }
    }
}
