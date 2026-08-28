//
//  NotificationsSheet.swift
//  Equitrip
//

import SwiftUI

/// What the bell opens. Unread items keep a full-strength card and an accent
/// rail; read ones recede rather than disappear, so the list stays a history.
///
/// Payments come first and come with buttons. Everything else in this list is
/// news you read and move past; a payment somebody recorded against a booking
/// you're on is a claim on your money, and the only useful thing to do with a
/// claim is agree with it or don't. Leaving those two answers out is what made
/// "settle with proof, not promises" a slogan rather than a feature.
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationStore) private var store
    @Environment(\.tripStore) private var trips

    private var pending: [AppNotification] { store.awaitingResponse }
    private var unread: [AppNotification] { store.unread.filter { !$0.needsResponse } }
    private var earlier: [AppNotification] { store.read }

    private var isEmpty: Bool { pending.isEmpty && unread.isEmpty && earlier.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if isEmpty {
                    emptyState
                } else {
                    if !pending.isEmpty {
                        group(title: "Needs you", items: pending, tint: AppTheme.accent)
                    }
                    if !unread.isEmpty {
                        group(title: "New", items: unread)
                    }
                    if !earlier.isEmpty {
                        group(title: "Earlier", items: earlier)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .presentationDragIndicator(.hidden)
        // Set as the presentation background rather than layered inside, so
        // the gradient clips to the sheet's own corner radius.
        .presentationBackground { CanvasBackground() }
        .refreshable { await store.load() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            if !store.unread.isEmpty {
                Button("Read all") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        store.markAllRead()
                    }
                }
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .buttonStyle(.plain)
            }

            CircleGlyphButton(symbol: "xmark", size: 36) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var subtitle: String {
        if !pending.isEmpty {
            return "\(pending.count.pluralised("payment")) waiting on you"
        }
        if store.unread.isEmpty { return "You're all caught up" }
        return "\(store.unread.count) unread · tap to read"
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)

            Text("Nothing yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text("Bookings, payments and arrivals on your trips land here.")
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    private func group(
        title: String,
        items: [AppNotification],
        tint: Color = AppTheme.inkTertiary
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(tint)
                .padding(.leading, 2)

            VStack(spacing: 10) {
                ForEach(items) { item in
                    NotificationCard(item: item) { response in
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                            store.respond(response, to: item, in: trips.trip(item.tripID))
                        }
                    } onRead: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            store.markRead(item.id)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Card

private struct NotificationCard: View {
    let item: AppNotification
    var onRespond: (AppNotification.Response) -> Void
    var onRead: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                guard item.isUnread else { return }
                onRead()
            } label: {
                summary
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!item.isUnread)

            if item.needsResponse {
                Hairline(inset: 14)
                responseBar
            } else if let response = item.response {
                Hairline(inset: 14)
                answered(response)
            }
        }
        .cardSurface(corner: 20, shadow: item.isUnread ? 14 : 8)
        .opacity(item.isUnread || item.needsResponse ? 1 : 0.72)
    }

    private var summary: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(item.kind.tint.opacity(item.isUnread ? 0.16 : 0.10))
                .overlay {
                    Image(systemName: item.kind.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.kind.tint)
                }
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    Text(item.time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .fixedSize()
                }

                if !item.body.isEmpty {
                    Text(item.body)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }

            if item.isUnread {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)
            }
        }
        .padding(14)
        .contentShape(.rect)
    }

    /// Two answers, equal weight.
    ///
    /// Disputing is not the destructive option and isn't styled as one — most
    /// disputes are "that was ₹1,800, not ₹8,100", which is somebody being
    /// helpful. Making it red would make raising one feel like an accusation,
    /// and a dispute nobody is willing to raise is a ledger that quietly
    /// disagrees with everyone's bank statement.
    private var responseBar: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onRespond(.disputed)
            } label: {
                responseLabel(symbol: "exclamationmark.bubble", title: "Dispute")
            }
            .buttonStyle(.glass)
            .tint(AppTheme.inkSecondary)

            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onRespond(.confirmed)
            } label: {
                responseLabel(symbol: "checkmark", title: "Confirm")
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.positive)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func responseLabel(symbol: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
    }

    private func answered(_ response: AppNotification.Response) -> some View {
        HStack(spacing: 7) {
            Image(systemName: response.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(response.tint)

            Text("You \(response.label.lowercased()) this")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .transition(.opacity)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) { NotificationsSheet() }
}
