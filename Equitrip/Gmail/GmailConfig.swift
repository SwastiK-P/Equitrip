//
//  GmailConfig.swift
//  Equitrip
//

import Foundation

/// Where the Gmail connection gets its identity.
///
/// An iOS OAuth client has no secret — Google stopped issuing one for native
/// apps precisely because a secret shipped inside an app isn't secret — so the
/// only thing here is the client ID, and PKCE does the work a secret used to.
/// That means this file is safe to commit; it is not, on its own, permission
/// to read anybody's mail.
///
/// Setup, once, in the Google Cloud console:
///
///  1. Create a project, then **APIs & Services ▸ Library ▸ Gmail API ▸ Enable**.
///  2. **OAuth consent screen**: External, add yourself under *Test users*.
///     The `gmail.readonly` scope is a restricted one — while the app is in
///     testing that's fine for up to 100 test users, and only a public release
///     needs Google's verification.
///  3. **Credentials ▸ Create credentials ▸ OAuth client ID ▸ iOS**, bundle ID
///     `com.swastik.Equitrip`.
///  4. Paste the client ID below, and add its reversed form as a URL scheme in
///     `Equitrip-Info.plist` (there's already an entry there for it).
enum GmailConfig {

    /// Looks like `123456789-abcdefg.apps.googleusercontent.com`.
    static let clientID = "1051629329168-1h41i6fme8gffggfpiirh6u1dh5j8v91.apps.googleusercontent.com"

    /// Read-only. The app never sends, never deletes, never labels — and
    /// asking for less is the difference between a consent screen somebody
    /// accepts and one they back out of.
    static let scope = "https://www.googleapis.com/auth/gmail.readonly"

    /// Google's convention for native apps: the client ID with its dot-parts
    /// reversed, used as a custom URL scheme.
    static var redirectScheme: String {
        let bare = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        return "com.googleusercontent.apps.\(bare)"
    }

    static var redirectURI: String { "\(redirectScheme):/oauth2redirect" }

    /// True once a real client ID has been pasted in. The settings row says so
    /// rather than opening a browser onto Google's "invalid client" page,
    /// which is the least explicable error in this entire flow.
    static var isConfigured: Bool {
        !clientID.hasPrefix("REPLACE_WITH_YOUR") && clientID.hasSuffix(".apps.googleusercontent.com")
    }

    static let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    static let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!
    static let revokeEndpoint = URL(string: "https://oauth2.googleapis.com/revoke")!
}
