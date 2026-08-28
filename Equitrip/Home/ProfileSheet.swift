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
    @State private var showNotificationSettings = false
    @State private var exported: ExportedFile?
    @State private var exportFailed = false

    /// Mirrors of the stored preferences. `AppSettings` is plain
    /// `UserDefaults` rather than `@AppStorage`, because it's read from
    /// non-view code — so the rows need something observable of their own to
    /// redraw against.
    @State private var currency = AppSettings.defaultCurrency
    @State private var method = AppSettings.defaultPaymentMethod
    /// Bumped whenever a notification channel is toggled, for the same reason.
    @State private var channelVersion = 0

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
                stats
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
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsSheet(version: $channelVersion)
        }
        .sheet(item: $exported) { file in
            ShareSheet(items: [file.url])
        }
        .alert("Couldn't write the ledger", isPresented: $exportFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There wasn't room to save the file. Free some space and try again.")
        }
        .onChange(of: currency) { _, new in AppSettings.defaultCurrency = new }
        .onChange(of: method) { _, new in AppSettings.defaultPaymentMethod = new }
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
                MemojiAvatar(traveller: .you, size: 88)
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

    // MARK: - Stats

    /// Read off the ledger rather than typed in. These were three invented
    /// figures — a trip count and two amounts that belonged to no trip anybody
    /// was on — sitting under the user's own name, which is the last place in
    /// the app that should be showing made-up money.
    private var stats: some View {
        HStack(spacing: 0) {
            stat(value: "\(store.trips.count)", label: store.trips.count == 1 ? "Trip" : "Trips")
            Divider().frame(height: 34).overlay(AppTheme.cardStroke.opacity(0.10))
            stat(value: Money.format(store.owedToYou, code: store.primaryCurrency), label: "Owed to you")
            Divider().frame(height: 34).overlay(AppTheme.cardStroke.opacity(0.10))
            stat(value: Money.format(store.youOwe, code: store.primaryCurrency), label: "You owe")
        }
        .padding(.vertical, 16)
        .cardSurface(corner: 22)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Settings

    private var settings: some View {
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
                symbol: "bell",
                title: "Notifications",
                value: notificationSummary
            ) { showNotificationSettings = true }

            Hairline(inset: 16)

            settingsRow(
                symbol: "square.and.arrow.up",
                title: "Export trip ledger",
                value: store.trips.isEmpty ? "No trips" : "\(store.trips.count) CSV"
            ) { exportLedger() }
        }
        .cardSurface(corner: 22)
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

    private func exportLedger() {
        guard let url = LedgerExport.write(store.trips) else {
            exportFailed = true
            return
        }
        exported = ExportedFile(url: url)
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
        HStack(spacing: 5) {
            Text("Made with")
            Image(systemName: "heart.fill")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.danger)
            Text("by Swastik")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(AppTheme.inkTertiary)
        .padding(.top, 4)
        .accessibilityElement()
        .accessibilityLabel("Made with love by Swastik")
    }
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
private struct SettingsSheetScaffold<Content: View>: View {
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
