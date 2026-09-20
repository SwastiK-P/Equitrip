//
//  ProfileSheet.swift
//  Equitrip
//

import SwiftUI

/// What the top-right avatar opens. Identity first, then the numbers that
/// follow you across trips, then settings, then the way out.
///
/// The settings rows used to be four coloured tiles — indigo, green, amber,
/// violet — under a heading, which read as four unrelated features rather than
/// one list, and none of the four did anything when tapped. They're the same
/// tile the onboarding feature cards use now: one fill, one glyph colour, no
/// swatch set. The glyphs are outlined rather than filled for the same reason
/// — a settings list is a table of contents, and a column of solid symbols
/// shouts louder than the words next to them.
struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    var userName: String?
    var onSignOut: () -> Void = {}

    @State private var showAvatarPicker = false
    /// Bumped when the avatar is saved. `CurrentUser` is process-wide state
    /// rather than observable, so nothing here would otherwise notice that the
    /// face changed.
    @State private var avatarVersion = 0

    @State private var showPaymentMethods = false
    @State private var showCurrency = false
    @State private var showUPISettings = false
    @State private var showNotificationSettings = false
    @State private var showGmailSettings = false
    @State private var showSiri = false
    /// Observed so the row's value line follows a connection made inside the
    /// sub-sheet without the profile screen being re-presented.
    @State private var gmail = GmailAccount.shared

    /// Mirrors of the stored preferences. `AppSettings` is plain
    /// `UserDefaults` rather than `@AppStorage`, because it's read from
    /// non-view code — so the rows need something observable of their own to
    /// redraw against.
    @State private var currency = AppSettings.defaultCurrency
    @State private var method = AppSettings.defaultPaymentMethod
    @State private var upiID = AppSettings.upiID
    /// Bumped whenever a notification channel is toggled, for the same reason.
    @State private var channelVersion = 0
    @State private var shakeToAdd = AppSettings.shakeToAddExpense
    /// Whether the "hint reset" confirmation is showing — see
    /// `resetShakeHint`. Not persisted; it only ever needs to be on screen
    /// for the couple of seconds after the long press that triggered it.
    @State private var shakeHintWasReset = false

    /// The colophon's heart burst. `heartBurstToken` is bumped on every tap
    /// so a retap's delayed cleanup can't clear the *newer* burst it started.
    @State private var heartBurst: [HeartConfettiParticle] = []
    @State private var heartBurstAnimating = false
    @State private var heartBurstToken = 0

    private var displayName: String {
        guard let userName, !userName.isEmpty else { return "Traveller" }
        return userName.contains("@") ? String(userName.split(separator: "@")[0]).capitalized : userName
    }

    private var handle: String {
        guard let userName, userName.contains("@") else { return "Signed in" }
        return userName
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                identity
                settings
                signOut
                colophon
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet { avatarVersion += 1 }
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodSettingsSheet(selection: $method)
        }
        .sheet(isPresented: $showCurrency) {
            CurrencyPickerSheet(selection: $currency)
        }
        .sheet(isPresented: $showUPISettings) {
            UPIIDSettingsSheet(upiID: $upiID)
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsSheet(version: $channelVersion)
        }
        .sheet(isPresented: $showGmailSettings) {
            GmailSettingsSheet()
        }
        .sheet(isPresented: $showSiri) {
            SiriSettingsSheet()
        }
        .onChange(of: currency) { _, new in AppSettings.defaultCurrency = new }
        .onChange(of: method) { _, new in AppSettings.defaultPaymentMethod = new }
        .onChange(of: shakeToAdd) { _, new in AppSettings.shakeToAddExpense = new }
        .onChange(of: upiID) { _, new in
            AppSettings.upiID = new
            Task { try? await SupabaseRepository.shared.updateUPIID(new) }
        }
        .task {
            // Only fills in a blank field — a reinstall or second device
            // that's never saved one locally. Never overwrites what's
            // already showing, or a resolve that's still in flight when the
            // user edits and saves would win the race and stomp it back.
            guard upiID.isEmpty else { return }
            _ = try? await SupabaseRepository.shared.resolveProfile()
            if upiID.isEmpty, let synced = CurrentUser.traveller.upiVPA {
                upiID = synced
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("You")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 36) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Identity

    private var identity: some View {
        VStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAvatarPicker = true
            } label: {
                TravellerAvatar(traveller: .you, size: 88)
                    .id(avatarVersion)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.ctaLabel)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.cta, in: .circle)
                            .overlay { Circle().strokeBorder(AppTheme.card, lineWidth: 2.5) }
                    }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Change your picture")

            VStack(spacing: 3) {
                Text(displayName)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(handle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .cardSurface(corner: 26)
    }

    
    // MARK: - Settings

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(AppTheme.inkTertiary)
            .padding(.leading, 6)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Preferences")

            VStack(spacing: 0) {
                settingsRow(
                    symbol: "creditcard",
                    title: "Payment methods",
                    value: method.label
                ) { showPaymentMethods = true }

                Hairline(inset: 16)

                settingsRow(
                    symbol: "banknote",
                    title: "Default currency",
                    value: "\(Money.symbol(for: currency)) \(currency)"
                ) { showCurrency = true }

                Hairline(inset: 16)

                settingsRow(
                    symbol: "indianrupeesign.circle",
                    title: "UPI ID",
                    value: upiID.isEmpty ? "Not set" : upiID
                ) { showUPISettings = true }

                Hairline(inset: 16)

                settingsRow(
                    symbol: "bell",
                    title: "Notifications",
                    value: notificationSummary
                ) { showNotificationSettings = true }

                Hairline(inset: 16)

                toggleRow(
                    symbol: "iphone.gen3.radiowaves.left.and.right",
                    title: "Shake for quick expense",
                    isOn: $shakeToAdd,
                    onLongPress: resetShakeHint
                )
            }
            .cardSurface(corner: 22)

            // Undocumented on purpose — the explainer only ever shows itself
            // once by design, and this exists so that "once" doesn't mean
            // "once per install" while building or testing the feature. A
            // long press is discoverable enough for that without turning it
            // into an actual settings row nobody else needs.
            if shakeHintWasReset {
                Text("Hint reset — the next shake will explain it again")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.leading, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            sectionHeader("Integrations")

            VStack(spacing: 0) {
                gmailRow
                Hairline(inset: 16)
                settingsRow(symbol: "waveform", title: "Siri", value: "What to say") { showSiri = true }
            }
            .cardSurface(corner: 22)
        }
    }

    private var notificationSummary: String {
        // Reading `channelVersion` is what ties this to the toggles: the
        // channels live in `UserDefaults`, which publishes nothing.
        _ = channelVersion
        let off = NotificationChannel.allCases.filter { !$0.isOn }.count
        if off == 0 { return "All on" }
        if off == NotificationChannel.allCases.count { return "All off" }
        return "\(NotificationChannel.allCases.count - off) of \(NotificationChannel.allCases.count)"
    }

    /// The one row that doesn't take an `IconTile`.
    ///
    /// Google's mark rather than an SF Symbol envelope, because this row is
    /// about somebody's Gmail account specifically and a generic glyph would
    /// under-state what it opens. Same geometry as the rest of the list, so it
    /// reads as one of them and not as an advert.
    private var gmailRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showGmailSettings = true
        } label: {
            HStack(spacing: 12) {
                GmailMark()
                    .frame(width: 20, height: 15)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.card, in: .rect(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke.opacity(0.1))
                    }

                Text("Gmail")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 6)

                Text(gmailSummary)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var gmailSummary: String {
        guard gmail.isConnected else { return "Connect" }
        return gmail.isEnabled ? (gmail.address ?? "Connected") : "Paused"
    }

    private func settingsRow(
        symbol: String,
        title: String,
        value: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                // No `tint`, which is what makes it the onboarding tile: one
                // fill for the whole list, glyph in the label colour.
                IconTile(symbol: symbol, size: 32, corner: 10)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 6)

                if let value {
                    Text(value)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// Same geometry as `settingsRow`, but for a preference that's a single
    /// on/off rather than a value that opens a sub-sheet — a switch instead
    /// of a chevron, nothing else about the row changes.
    private func toggleRow(
        symbol: String,
        title: String,
        isOn: Binding<Bool>,
        onLongPress: (() -> Void)? = nil
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                IconTile(symbol: symbol, size: 32, corner: 10)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.ink)
            }
            .contentShape(.rect)
            // Alongside the toggle's own tap, not instead of it — a long
            // press still ends in a tap being recognised on release, so this
            // has to not fight that for the row to keep switching normally.
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in onLongPress?() }
            )
        }
        .tint(AppTheme.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    /// Replays the shake-to-add explainer on the next shake — a long press
    /// on its row, for testing the feature without reinstalling just to
    /// clear the "already seen it" flag.
    private func resetShakeHint() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        AppSettings.hasSeenShakeHint = false

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shakeHintWasReset = true }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeOut(duration: 0.25)) { shakeHintWasReset = false }
        }
    }

    // MARK: - Sign out

    private var signOut: some View {
        Button {
            dismiss()
            onSignOut()
        } label: {
            Text("Sign out")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .cardSurface(corner: 20, shadow: 10)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Colophon

    private var colophon: some View {
        Button {
            burstHearts()
        } label: {
            HStack(spacing: 6) {
                Text("Made with")
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.danger)
                Text("by Swastik")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.inkTertiary)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .overlay { heartConfetti }
        .accessibilityElement()
        .accessibilityLabel("Made with love by Swastik")
    }

    /// Hearts thrown from the colophon on tap — the one unserious thing on
    /// this screen, and the only place it's earned. Particles are created
    /// with their rest position first (no animation), then a single flag flip
    /// inside `withAnimation` carries them all outward together; that's what
    /// keeps a retap from restarting mid-burst into a jump cut.
    @ViewBuilder
    private var heartConfetti: some View {
        ZStack {
            ForEach(heartBurst) { heart in
                Image(systemName: "heart.fill")
                    .font(.system(size: 12 * heart.scale, weight: .semibold))
                    .foregroundStyle(AppTheme.danger.opacity(heart.opacity))
                    .rotationEffect(.degrees(heartBurstAnimating ? heart.rotation : 0))
                    .scaleEffect(heartBurstAnimating ? heart.scale : 0.4)
                    .offset(x: heartBurstAnimating ? heart.dx : 0, y: heartBurstAnimating ? heart.dy : 0)
                    .opacity(heartBurstAnimating ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
    }

    private func burstHearts() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        heartBurstToken += 1
        heartBurstAnimating = false
        heartBurst = (0..<14).map { _ in
            HeartConfettiParticle(
                dx: CGFloat.random(in: -90...90),
                dy: CGFloat.random(in: -130 ... -30),
                rotation: Double.random(in: -70...70),
                scale: CGFloat.random(in: 0.6...1.25),
                opacity: Double.random(in: 0.65...1)
            )
        }

        withAnimation(.easeOut(duration: 0.9)) {
            heartBurstAnimating = true
        }

        let burstID = heartBurstToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard burstID == heartBurstToken else { return }
            heartBurst = []
            heartBurstAnimating = false
        }
    }
}

/// One heart in the colophon's tap burst, at its rest state — `dx`/`dy` etc.
/// are the *outward* offset it animates to, not where it starts.
private struct HeartConfettiParticle: Identifiable {
    let id = UUID()
    let dx: CGFloat
    let dy: CGFloat
    let rotation: Double
    let scale: CGFloat
    let opacity: Double
}

// MARK: - Payment methods

/// Which way of paying the app assumes.
private struct PaymentMethodSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: PaymentMethod

    var body: some View {
        SettingsSheetScaffold(
            title: "Payment methods",
            caption: "Pre-selected whenever somebody records a payment."
        ) {
            VStack(spacing: 0) {
                ForEach(Array(PaymentMethod.allCases.enumerated()), id: \.element.id) { index, option in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selection = option
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            IconTile(symbol: option.symbol, size: 32, corner: 10)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(option.label)
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppTheme.ink)

                                Text(option.isOnline ? "Leaves a receipt worth attaching" : "No receipt to attach")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }

                            Spacer(minLength: 6)

                            Image(systemName: selection == option ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundStyle(selection == option ? AppTheme.accent : AppTheme.inkTertiary.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if index < PaymentMethod.allCases.count - 1 {
                        Hairline(inset: 16)
                    }
                }
            }
            .cardSurface(corner: 22)
        }
    }
}

// MARK: - UPI ID

/// Your own VPA, so it's typed once here rather than re-typed into every
/// settlement that happens to be paid your way.
private struct UPIIDSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var upiID: String
    @State private var draft: String
    @FocusState private var focused: Bool

    init(upiID: Binding<String>) {
        _upiID = upiID
        _draft = State(initialValue: upiID.wrappedValue)
    }

    private var trimmed: String { draft.trimmingCharacters(in: .whitespaces) }
    private var isValid: Bool { trimmed.isEmpty || UPILink.looksValid(trimmed) }

    var body: some View {
        SettingsSheetScaffold(
            title: "UPI ID",
            caption: "Your VPA — the same one your UPI app already shows you."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                GlassField(
                    label: "Your VPA",
                    placeholder: "yourname@okhdfcbank",
                    text: $draft,
                    symbol: "indianrupeesign.circle",
                    keyboard: .emailAddress,
                    autocapitalisation: .never
                )
                .focused($focused)

                if !isValid {
                    Label("Looks like it's missing the @bank part.", systemImage: "exclamationmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.danger)
                        .padding(.leading, 2)
                }

                PrimaryButton(title: "Save", systemImage: "checkmark", isEnabled: isValid) {
                    upiID = trimmed
                    GlassToastCenter.shared.show(.init(
                        symbol: "indianrupeesign.circle.fill",
                        tint: AppTheme.accent,
                        title: "UPI ID saved",
                        subtitle: "People settling up with you will see this.",
                        duration: .seconds(3)
                    ))
                    dismiss()
                }
                .padding(.top, 6)
            }
        }
        .onAppear { focused = upiID.isEmpty }
    }
}

// MARK: - Notification settings

/// Which events reach you.
///
/// Four switches rather than one master toggle, because the reasons people
/// mute differ: an organiser wants every booking change and none of the
/// balance arithmetic, and somebody who's only along for the ride wants the
/// opposite. Muting hides events from the feed — it never stops them being
/// recorded, so turning a channel back on shows what happened while it was off.
private struct NotificationSettingsSheet: View {
    @Binding var version: Int

    var body: some View {
        SettingsSheetScaffold(
            title: "Notifications",
            caption: "Muting hides events from your feed. Nothing stops being recorded."
        ) {
            VStack(spacing: 0) {
                ForEach(Array(NotificationChannel.allCases.enumerated()), id: \.element.id) { index, channel in
                    Toggle(isOn: binding(for: channel)) {
                        HStack(spacing: 12) {
                            IconTile(symbol: channel.symbol, size: 32, corner: 10)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(channel.title)
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppTheme.ink)

                                Text(channel.detail)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }
                        }
                    }
                    .tint(AppTheme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)

                    if index < NotificationChannel.allCases.count - 1 {
                        Hairline(inset: 16)
                    }
                }
            }
            .cardSurface(corner: 22)
        }
    }

    private func binding(for channel: NotificationChannel) -> Binding<Bool> {
        Binding(
            get: {
                _ = version
                return channel.isOn
            },
            set: { on in
                channel.isOn = on
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                version += 1
            }
        )
    }
}

// MARK: - Scaffold

/// The shape every settings sub-sheet takes: title, one line of why, content.
struct SettingsSheetScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    var caption: String?
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let caption {
                    Text(caption)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 2)
                }

                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                    .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProfileSheet(userName: "Swastik Patil")
    }
}
