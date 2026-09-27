//
//  GmailSettingsSheet.swift
//  Equitrip
//

import SwiftUI

/// Connecting the mailbox, and saying plainly what that means.
///
/// This screen is asking for read access to somebody's email, which is the
/// largest thing this app ever asks for. So it says the things that actually
/// bound it — only around a trip, only payment and booking mail, and the
/// reading happens on the phone — before the button, not after it in a
/// footnote. Anything less and the honest answer to "what is this doing with
/// my mail" is "I don't know", which is not an answer a person should have to
/// accept to split a dinner bill.
struct GmailSettingsSheet: View {
    @Environment(\.tripStore) private var store
    @Environment(\.detectedExpenses) private var detections
    @Environment(\.gmailSync) private var sync
    @Environment(\.bookingChangeSync) private var bookingSync
    @Environment(\.bookingChanges) private var bookingChanges

    @State private var account = GmailAccount.shared
    @State private var confirmingDisconnect = false
    @State private var showingBookingChanges = false

    private var liveTrip: Trip? { store.trips.first { $0.phase == .live } }

    var body: some View {
        SettingsSheetScaffold(
            title: "Gmail",
            caption: "Reads your bank's payment alerts while a trip is running, and booking cancellations and reschedules in the month before one."
        ) {
            VStack(spacing: 14) {
                accountCard

                // Directly under the button that produced it. This sheet opens
                // at the medium detent, and four explanatory rows tall enough
                // to push the failure below the fold is the same thing as not
                // reporting it: the connection quietly doesn't happen and the
                // screen goes back to offering the button.
                if let error = account.lastError {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)

                        Text(error)
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.danger.opacity(0.1), in: .rect(cornerRadius: 16, style: .continuous))
                }

                if account.isConnected {
                    activityCard
                }

                bookingChangesCard

                if !account.isConnected {
                    // Once the mailbox is connected the promises have already
                    // been read and agreed to; the sheet becomes a status
                    // screen instead of a pitch.
                    promises
                }
            }
        }
        .sheet(isPresented: $showingBookingChanges) { BookingChangesSheet() }
        .alert("Disconnect Gmail?", isPresented: $confirmingDisconnect) {
            Button("Disconnect", role: .destructive) {
                Task { await account.disconnect() }
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Equitrip stops reading your mail. Expenses you already added stay on the trip.")
        }
    }

    // MARK: - Account

    private var accountCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                GmailMark()
                    .frame(width: 30, height: 23)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.card, in: .rect(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.isConnected ? "Gmail connected" : "Connect Gmail")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)

                    Text(statusLine)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 6)

                if account.isConnecting {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Hairline(inset: 16)

            if account.isConnected {
                Toggle(isOn: Binding(get: { account.isEnabled }, set: { account.isEnabled = $0 })) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Detect expenses")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.ink)
                        Text("Pause without disconnecting.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }
                .tint(AppTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)

                Hairline(inset: 16)

                Button {
                    confirmingDisconnect = true
                } label: {
                    Text("Disconnect")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await account.connect() }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "link")
                            .font(.system(size: 13, weight: .bold))
                        Text(GmailConfig.isConfigured ? "Connect Gmail" : "Not set up in this build")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(GmailConfig.isConfigured ? AppTheme.accent : AppTheme.inkTertiary)
                .disabled(!GmailConfig.isConfigured || account.isConnecting)
            }
        }
        .cardSurface(corner: 22)
    }

    private var statusLine: String {
        guard GmailConfig.isConfigured else {
            return "This build has no Google client ID yet."
        }
        if let address = account.address { return address }
        // Connected, but Google's profile call didn't answer. The connection
        // is real and works; only the label is missing.
        if account.isConnected { return "Connected" }
        return "Read-only access to your payment alerts."
    }

    // MARK: - Activity

    /// What it has actually been doing. A connection that silently found
    /// nothing and a connection that silently broke look identical without
    /// this, and the second one is the one worth knowing about.
    private var activityCard: some View {
        VStack(spacing: 0) {
            row(
                symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                title: "Last checked",
                value: lastCheckedText
            )

            Hairline(inset: 16)

            row(
                symbol: "suitcase",
                title: "Watching",
                value: liveTrip.map { "\($0.title) · until \(DateFormatter.cached("d MMM").string(from: $0.endDate))" }
                    ?? "Nothing — no trip is running"
            )

            Hairline(inset: 16)

            row(
                symbol: "tray",
                title: "Waiting to be added",
                value: "\(detections.waitingCount(for: liveTrip?.id))"
            )

            if let failure = sync?.state.failure {
                Hairline(inset: 16)
                row(symbol: "exclamationmark.triangle", title: "Last run", value: failure, tint: AppTheme.danger)
            }
        }
        .cardSurface(corner: 22)
    }

    // MARK: - Booking changes

    /// Its own card and its own switch: it reads outside the running trip,
    /// which the expense switch never promised.
    private var bookingChangesCard: some View {
        VStack(spacing: 0) {
            if let bookingSync {
                toggle(
                    "Watch for booking changes",
                    detail: "Cancellations and reschedules for trips starting within 30 days.",
                    isOn: Binding(get: { bookingSync.isEnabled }, set: { bookingSync.isEnabled = $0 })
                )
                .disabled(!account.isConnected)
                .opacity(account.isConnected ? 1 : 0.5)

                Hairline(inset: 16)

                toggle(
                    "Apply changes automatically",
                    detail: "Off: every change waits for you to confirm. On: when the booking is unmistakable, it's applied while you watch — with Undo.",
                    isOn: Binding(get: { bookingSync.appliesAutomatically }, set: { bookingSync.appliesAutomatically = $0 })
                )

                Hairline(inset: 16)

                toggle(
                    "Tell the trip chat",
                    detail: "Post a note in the group's chat when a change is applied.",
                    isOn: Binding(get: { bookingSync.postsToChat }, set: { bookingSync.postsToChat = $0 })
                )

                Hairline(inset: 16)
            }

            Button {
                showingBookingChanges = true
            } label: {
                HStack(spacing: 12) {
                    IconTile(symbol: "calendar.badge.clock", size: 32, corner: 10)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Booking changes")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.ink)
                        Text("Everything found, and what was done about it")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    Spacer(minLength: 6)
                    let count = bookingChanges.waiting().count
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .cardSurface(corner: 22)
    }

    private func toggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(AppTheme.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var lastCheckedText: String {
        guard let last = sync?.lastSyncedAt else { return "Not yet" }
        let minutes = Int(Date().timeIntervalSince(last) / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        return DateFormatter.cached("d MMM, h:mm a").string(from: last)
    }

    private func row(symbol: String, title: String, value: String, tint: Color? = nil) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: symbol, size: 32, corner: 10)

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 6)

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint ?? AppTheme.inkTertiary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - What it does

    private var promises: some View {
        VStack(alignment: .leading, spacing: 0) {
            promise(
                symbol: "calendar.badge.clock",
                title: "Only around your trips",
                detail: "Payment alerts while a trip is running; booking changes from 30 days before it starts. Otherwise the app doesn't open your mailbox at all."
            )

            Hairline(inset: 16)

            promise(
                symbol: "line.3.horizontal.decrease",
                title: "Only payment and booking mail",
                detail: "The search asks Gmail for payment alerts and for cancellations and reschedules. Promotions, newsletters and personal mail are excluded before anything is downloaded."
            )

            Hairline(inset: 16)

            promise(
                symbol: "iphone",
                title: "Read on this iPhone",
                detail: "Apple Intelligence reads each alert on device. No email text is uploaded, stored or shared with anyone on your trip."
            )

            Hairline(inset: 16)

            promise(
                symbol: "hand.raised",
                title: "Money never moves by itself",
                detail: "A detected payment waits for you to name it and split it. Every booking change asks you to confirm first, unless you turn on applying them automatically."
            )
        }
        .cardSurface(corner: 22)
    }

    private func promise(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(symbol: symbol, size: 32, corner: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
