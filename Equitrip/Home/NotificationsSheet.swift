//
//  NotificationsSheet.swift
//  Equitrip
//

import SwiftUI

/// What the bell opens. Unread items keep a full-strength card and an accent
/// rail; read ones recede rather than disappear, so the list stays a history.
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationStore) private var store

    private var unread: [AppNotification] { store.unread }
    private var earlier: [AppNotification] { store.read }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !unread.isEmpty {
                    group(title: "New", items: unread)
                }
                if !earlier.isEmpty {
                    group(title: "Earlier", items: earlier)
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
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(unread.isEmpty ? "You're all caught up" : "\(unread.count) unread · tap to read")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            if !unread.isEmpty {
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

    private func group(title: String, items: [AppNotification]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            VStack(spacing: 10) {
                ForEach(items) { item in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            store.markRead(item.id)
                        }
                    } label: {
                        NotificationCard(item: item)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(!item.isUnread)
                }
            }
        }
    }
}

private struct NotificationCard: View {
    let item: AppNotification

    var body: some View {
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

                    Spacer(minLength: 0)

                    Text(item.time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .fixedSize()
                }

                Text(item.body)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if item.isUnread {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)
            }
        }
        .padding(14)
        .cardSurface(corner: 20, shadow: item.isUnread ? 14 : 8)
        .opacity(item.isUnread ? 1 : 0.72)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) { NotificationsSheet() }
}
