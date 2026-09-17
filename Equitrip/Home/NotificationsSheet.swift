//
//  NotificationsSheet.swift
//  Equitrip
//

import SwiftUI

/// What the bell opens. Unread items keep a full-strength card and an accent
/// rail; read ones recede rather than disappear, so the list stays a history.
///
/// Purely a feed — a payment somebody recorded is taken as confirmed the
/// moment it lands here, and there's nothing to answer. Anyone who thinks a
/// payment is wrong reports it from the booking itself, not from this list.
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationStore) private var store

    /// Nil means "All". A person on a busy trip has expenses, bookings and
    /// arrivals all landing in one feed, and "just show me the money stuff"
    /// is a question worth answering without scrolling for it.
    @State private var filter: NotificationChannel?

    private var filtered: [AppNotification] {
        guard let filter else { return store.feed }
        return store.feed.filter { $0.kind.channel == filter }
    }

    private var unread: [AppNotification] { filtered.filter(\.isUnread) }
    private var earlier: [AppNotification] { filtered.filter { !$0.isUnread } }

    private var isEmpty: Bool { unread.isEmpty && earlier.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !store.feed.isEmpty {
                    filters
                }

                if isEmpty {
                    emptyState
                } else {
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
        if store.unread.isEmpty { return "You're all caught up" }
        return "\(store.unread.count) unread · tap to read"
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                NotificationFilterChip(label: "All", count: store.feed.count, isOn: filter == nil) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { filter = nil }
                }

                ForEach(Self.channelsPresent(in: store.feed)) { channel in
                    NotificationFilterChip(
                        label: channel.title,
                        count: store.feed.filter { $0.kind.channel == channel }.count,
                        isOn: filter == channel
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { filter = channel }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    /// Only the categories actually represented — a "People" chip on a feed
    /// with nobody having joined anything is a filter for an empty list.
    private static func channelsPresent(in feed: [AppNotification]) -> [NotificationChannel] {
        let present = Set(feed.map(\.kind.channel))
        return NotificationChannel.allCases.filter { present.contains($0) }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)

            Text("Nothing yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(
                filter == nil
                    ? "Bookings, payments and arrivals on your trips land here."
                    : "Nothing in \(filter!.title.lowercased()) yet."
            )
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
                    NotificationCard(item: item) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            store.markRead(item.id)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter chip

private struct NotificationFilterChip: View {
    let label: String
    let count: Int
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))

                Text("\(count)")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(isOn ? AppTheme.ctaLabel : AppTheme.inkSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(isOn ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(isOn ? 0 : 0.07)) }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card

private struct NotificationCard: View {
    let item: AppNotification
    var onRead: () -> Void

    var body: some View {
        Button {
            guard item.isUnread else { return }
            onRead()
        } label: {
            summary
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!item.isUnread)
        .cardSurface(corner: 20, shadow: item.isUnread ? 14 : 8)
        .opacity(item.isUnread ? 1 : 0.72)
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
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) { NotificationsSheet() }
}
