//
//  Components.swift
//  Equitrip
//

import SwiftUI

// MARK: - Buttons

/// Slight give on tap so buttons feel physical.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The filled, high-contrast action button used once per screen.
struct PrimaryButton: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    var systemImage: String? = "arrow.right"
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            ZStack {
                // Kept in the layout while loading so the button never resizes.
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .opacity(isLoading ? 0 : 1)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.ctaLabel)
                    .opacity(isLoading ? 1 : 0)
            }
            .foregroundStyle(AppTheme.ctaLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.cta, in: .rect(cornerRadius: 18))
            .shadow(color: AppTheme.softShadow(scheme), radius: 18, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(.easeOut(duration: 0.2), value: isLoading)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

/// Low-emphasis text action.
struct TextButton: View {
    let title: String
    var emphasis: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let emphasis {
                    Text("\(title) \(Text(emphasis).foregroundColor(AppTheme.accent).bold())")
                } else {
                    Text(title)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppTheme.inkSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Text field

/// Labelled field with an animated focus ring, matching the card surfaces.
struct EquitripField<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme

    let label: String
    let placeholder: String
    @Binding var text: String

    var isSecure: Bool = false
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .next

    /// Shared focus binding so the parent can drive field-to-field submission.
    @FocusState.Binding var focus: Value?
    let field: Value
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false

    private var isFocused: Bool { focus == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(isFocused ? AppTheme.accent : AppTheme.inkSecondary)

            HStack(spacing: 11) {
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .focused($focus, equals: field)
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15)
            .frame(height: 54)
            .background(AppTheme.card, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isFocused ? AppTheme.accent : AppTheme.cardStroke.opacity(scheme == .dark ? 0.12 : 0.07),
                        lineWidth: isFocused ? 1.6 : 1
                    )
            }
            .shadow(color: AppTheme.softShadow(scheme), radius: isFocused ? 12 : 6, y: isFocused ? 5 : 3)
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

// MARK: - Shake

/// Horizontal shake for rejected input. Driven by incrementing an integer, so
/// each failed attempt animates even when the error text is unchanged.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 7
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

extension View {
    func shake(_ trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}

// MARK: - Canvas

/// The single-hue peach gradient every screen in the app sits on.
struct CanvasBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.canvasTop, AppTheme.canvasBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card surface

/// The white card the whole app is built from: fill, hairline edge and a
/// warm-tinted lift. Applied as a modifier so every card matches by default
/// and one-off cards can't drift.
struct CardSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    var corner: CGFloat = 20
    var shadow: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(AppTheme.card, in: .rect(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(scheme == .dark ? 0.09 : 0.045))
            }
            .shadow(color: AppTheme.softShadow(scheme), radius: shadow, y: shadow * 0.35)
    }
}

extension View {
    func cardSurface(corner: CGFloat = 20, shadow: CGFloat = 10) -> some View {
        modifier(CardSurface(corner: corner, shadow: shadow))
    }
}

/// Row separator that matches the card edge instead of the system grey.
struct Hairline: View {
    @Environment(\.colorScheme) private var scheme

    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(scheme == .dark ? 0.10 : 0.07))
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - Section header

/// Title above a group of cards, with an optional trailing action.
struct SectionHeader: View {
    let title: String
    var caption: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            if let caption {
                Text(caption)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                            .font(.system(size: 13.5, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

// MARK: - Connection

/// Says the server couldn't be reached, and offers the one thing that helps.
///
/// Deliberately a banner rather than a full-screen error: whatever was already
/// loaded stays readable underneath it. Losing the connection halfway through
/// a trip shouldn't blank the trip.
struct ConnectionBanner: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.danger)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text("Couldn't reach the server")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(message)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Button("Try again", action: retry)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .buttonStyle(PressableButtonStyle())
        }
        .padding(14)
        .background(AppTheme.danger.opacity(0.07), in: .rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.danger.opacity(0.18))
        }
    }
}

/// The "we're still asking" state, shaped like the content it will become so
/// the screen doesn't jump when the answer arrives.
struct LoadingState: View {
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppTheme.inkTertiary)

            Text(message)
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chips

/// Small capsule label. Tint carries the meaning; the fill is a wash of it.
struct TagChip: View {
    let title: String
    var tint: Color = AppTheme.accent
    var symbol: String?

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(tint.opacity(0.13), in: .capsule)
    }
}

// MARK: - Circular glyph button

/// Glass circle carrying a single SF Symbol — the top-bar affordance.
struct CircleGlyphButton: View {
    let symbol: String
    var size: CGFloat = 44
    var action: () -> Void

    var body: some View {
        GlassCircleButton(size: size, action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}

/// The notifications bell.
///
/// Uses SF Symbols' own `bell.badge` rather than a hand-drawn count bubble:
/// the badge is part of the glyph, so it sits where Apple puts it, scales with
/// the symbol and never gets clipped by the circle around it.
struct NotificationBellButton: View {
    var unread: Int
    var size: CGFloat = 50
    let action: () -> Void

    var body: some View {
        GlassCircleButton(size: size, action: action) {
            Image(systemName: unread > 0 ? "bell.badge" : "bell")
                .font(.system(size: size * 0.38, weight: .medium))
                .symbolRenderingMode(unread > 0 ? .palette : .monochrome)
                .foregroundStyle(
                    unread > 0 ? AppTheme.danger : AppTheme.ink,
                    AppTheme.ink
                )
        }
        .accessibilityLabel(unread > 0 ? "Notifications, \(unread) unread" : "Notifications")
    }
}

// MARK: - Travellers

/// The memoji artwork already carries its own pastel backdrop, so clipping to
/// a circle gives a perfectly matched fill with no extra tinting.
///
/// A traveller who has uploaded a photograph gets that instead of the memoji,
/// not behind it — the two are exclusive, not layered. The memoji is only
/// ever what's drawn while the photo is still loading; once it succeeds the
/// memoji is gone entirely, and a broken URL falls back to it rather than
/// showing both at once.
struct MemojiAvatar: View {
    @Environment(\.colorScheme) private var scheme
    let traveller: Traveller
    var size: CGFloat

    var body: some View {
        Group {
            if let url = traveller.avatarURL {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        memoji
                    }
                }
            } else {
                memoji
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay {
            Circle().strokeBorder(AppTheme.card, lineWidth: size > 30 ? 2.5 : 1.5)
        }
        .shadow(color: AppTheme.softShadow(scheme), radius: 5, y: 2)
    }

    private var memoji: some View {
        Image(traveller.asset)
            .resizable()
            .scaledToFill()
    }
}

/// Overlapping avatar cluster with an overflow count, so a twelve-person trip
/// reads at the same width as a three-person one.
struct AvatarStack: View {
    let travellers: [Traveller]
    var size: CGFloat = 32
    var max: Int = 4

    private var shown: ArraySlice<Traveller> { travellers.prefix(max) }
    private var overflow: Int { Swift.max(0, travellers.count - max) }

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(Array(shown.enumerated()), id: \.offset) { slot, traveller in
                MemojiAvatar(traveller: traveller, size: size)
                    .zIndex(Double(shown.count - slot))
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .frame(width: size, height: size)
                    .background(AppTheme.canvasBottom, in: .circle)
                    .overlay { Circle().strokeBorder(AppTheme.card, lineWidth: size > 30 ? 2.5 : 1.5) }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(travellers.count.pluralised("traveller"))
    }
}

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

    init(
        id: UUID = UUID(),
        name: String,
        asset: String,
        email: String? = nil,
        isRegistered: Bool = false,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.asset = asset
        self.email = email
        self.isRegistered = isRegistered
        self.avatarURL = avatarURL
    }

    var initial: String { String(name.prefix(1)) }

    // Memberwise, for the same reason as `ItineraryItem` — `id` alone hid
    // renames from SwiftUI, and "you" keeps one fixed id across the sign-in
    // that finally gives it a real name.

    static let ed = Traveller(name: "Ed", asset: "MemojiEd")
    static let krishna = Traveller(name: "Krishna", asset: "MemojiKrishna")
    static let mattew = Traveller(name: "Mattew", asset: "MemojiMattew")
    static let kim = Traveller(name: "Kim", asset: "MemojiKim")
    /// Onboarding-only — shown before sign-in, so it needs a person who
    /// isn't "you". Reuses the Chris artwork; nothing else references it by
    /// name.
    static let priya = Traveller(name: "Priya", asset: "MemojiChris")

    /// The signed-in traveller.
    static var you: Traveller { CurrentUser.traveller }

    static var all: [Traveller] { [you, ed, krishna, mattew, kim] }

    /// Every memoji somebody can pick for themselves. Ordered, so the picker
    /// doesn't reshuffle between openings.
    static let memoji = ["MemojiChris", "MemojiEd", "MemojiKrishna", "MemojiMattew", "MemojiKim"]
}

/// Who "you" are, app-wide.
///
/// The identity is a fixed UUID set once at launch, so every `participantIDs`
/// set, every avatar and every "is this mine?" check agrees — including across
/// trips created before the display name was known. Only the label changes
/// when the session resolves.
enum CurrentUser {
    private nonisolated(unsafe) static var displayName = "You"
    /// The memoji behind the avatar. Overwritten by whichever one the user
    /// picks, and by whatever their profile row already said on sign-in.
    private nonisolated(unsafe) static var avatarAsset = "MemojiChris"
    /// A photograph they chose, which wins over the memoji.
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

    static var traveller: Traveller {
        Traveller(
            id: identity,
            name: displayName,
            asset: avatarAsset,
            email: address,
            isRegistered: true,
            avatarURL: avatarURL
        )
    }

    /// Records the face this account carries. Both together, always: a memoji
    /// picked after a photograph has to clear that photograph, or the photo
    /// keeps winning and the pick looks like it did nothing.
    static func adoptAvatar(asset: String, url: URL?) {
        avatarAsset = asset
        avatarURL = url
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
        avatarAsset = "MemojiChris"
        avatarURL = nil
    }

    static func isYou(_ name: String) -> Bool {
        name.caseInsensitiveCompare(displayName) == .orderedSame
    }
}

// MARK: - Shared icon tile

/// Solid tile carrying a white glyph. Defaults to the same fill as the primary
/// button so icon rows read as one family rather than a colour swatch set.
struct IconTile: View {
    @Environment(\.colorScheme) private var scheme

    let symbol: String
    var tint: Color?
    var size: CGFloat = 38
    var corner: CGFloat = 11

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(tint ?? AppTheme.cta)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(tint == nil ? AppTheme.ctaLabel : .white)
            }
            .frame(width: size, height: size)
            .shadow(color: AppTheme.softShadow(scheme), radius: 8, y: 4)
    }
}

// MARK: - Entrance

extension View {
    /// Shared stagger so every screen enters with the same rhythm as onboarding.
    func staggered(_ index: Int, _ appeared: Bool, base: Double = 0.05) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.86).delay(base * Double(index)),
                value: appeared
            )
    }
}

// MARK: - Progressive blur

// MARK: - Glass chrome

/// Circular Liquid Glass control. The whole navigation layer of the app is
/// built from these, so the chrome reads as one material and the content
/// cards below stay opaque.
struct GlassCircleButton<Content: View>: View {
    var size: CGFloat = 44
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            content
                .frame(width: size, height: size)
                // Without this the tap target is the glyph's own pixels, not
                // the circle it appears to be.
                .contentShape(.circle)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Symbol badge

/// Soft tinted disc carrying a matching glyph. The quiet counterpart to
/// `IconTile`: used in list rows, where a grid of saturated tiles would shout.
struct SymbolBadge: View {
    let symbol: String
    var tint: Color
    var size: CGFloat = 36

    var body: some View {
        Circle()
            .fill(tint.opacity(0.14))
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: size, height: size)
    }
}

// MARK: - Screen metrics

enum ScreenInsets {
    /// The status-bar / notch inset. Needed when a hero image has to run up
    /// behind a top bar that a `safeAreaInset` has already accounted for —
    /// SwiftUI has consumed the inset by then, so read it from the window.
    static var top: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        return scene?.windows.first { $0.isKeyWindow }?.safeAreaInsets.top
            ?? scene?.windows.first?.safeAreaInsets.top
            ?? 59
    }
}

// MARK: - Identifiable strings

/// Lets a plain code drive `sheet(item:)`, which needs identity rather than a
/// separate boolean plus a value that can drift out of sync with it.
extension String: @retroactive Identifiable {
    public var id: String { self }
}
