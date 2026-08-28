//
//  NotificationStore.swift
//  Equitrip
//

import SwiftUI

/// The notification list, and whether you've read it.
///
/// Separate from `TripStore` because notifications outlive the thing they
/// describe — a refund on a trip that's since been settled is still worth
/// reading — and because the unread count is consulted from the top bar on
/// every screen.
///
/// Backed by the `notifications` table. Reads and writes are optimistic: the
/// list updates on device first and the server catches up, because marking
/// something read is not worth a spinner.
@MainActor
@Observable
final class NotificationStore {
    private(set) var items: [AppNotification]
    private(set) var isLoading = false

    init(items: [AppNotification] = []) {
        self.items = items.sorted { $0.date > $1.date }
    }

    var unreadCount: Int { items.filter(\.isUnread).count }
    var unread: [AppNotification] { items.filter(\.isUnread) }
    var read: [AppNotification] { items.filter { !$0.isUnread } }

    // MARK: - Loading

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // A failure leaves the list exactly as it was. An empty feed is a
        // perfectly ordinary state here and the sheet says so itself, so
        // there's nothing an error banner would add that the bell doesn't
        // already communicate by staying quiet.
        guard let remote = try? await SupabaseRepository.shared.loadNotifications() else { return }
        items = remote.sorted { $0.date > $1.date }
    }

    // MARK: - Read state

    func markRead(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].isUnread else { return }
        items[index].isUnread = false
        Task { await SupabaseRepository.shared.markNotificationRead(id) }
    }

    func markAllRead() {
        guard unreadCount > 0 else { return }
        for index in items.indices where items[index].isUnread {
            items[index].isUnread = false
        }
        Task { await SupabaseRepository.shared.markAllNotificationsRead() }
    }

    // MARK: - Posting

    /// Files a notification for everyone named, and shows it here immediately
    /// if you're one of them.
    func post(_ notification: AppNotification, to recipients: [UUID]) {
        if recipients.contains(Traveller.you.id) {
            items.insert(notification, at: 0)
        }

        Task {
            for recipient in recipients {
                await SupabaseRepository.shared.post(notification, to: recipient)
            }
        }
    }

    /// Everyone on the trip hears about a new arrival.
    ///
    /// The joiner is excluded on purpose — being told you joined something you
    /// just joined is noise, and it's the people already on the trip who need
    /// to know the split maths just changed under them.
    func announceJoin(of joiner: Traveller, to trip: Trip) {
        guard joiner.id != Traveller.you.id else { return }

        let recipients = trip.travellers.map(\.id).filter { $0 != joiner.id }
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .joined,
                title: "\(joiner.name) joined \(trip.title)",
                body: trip.items.isEmpty
                    ? "They're on the trip. Nothing is shared with them yet."
                    : "Shares on \(trip.items.count.pluralised("booking")) will recalculate once they're added to them.",
                tripID: trip.id
            ),
            to: recipients
        )
    }
}

extension EnvironmentValues {
    @Entry var notificationStore = NotificationStore()
}
