//
//  BookingChangesInboxCard.swift
//  Equitrip
//

import SwiftUI

/// Home's line into the booking-change queue.
///
/// Only on screen when there's something to say: changes waiting for an
/// answer, or changes applied automatically that nobody has looked at yet.
/// The second matters as much as the first — a flight that moved by itself
/// and was never mentioned is exactly the surprise this feature exists to
/// prevent.
struct BookingChangesInboxCard: View {
    let waiting: [BookingChange]
    let applied: [BookingChange]
    var open: () -> Void

    @Environment(\.tripStore) private var store

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            open()
        } label: {
            HStack(spacing: 13) {
                BookingChangeCard.Badge(done: waiting.isEmpty)

                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    Text(detail)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .cardSurface(corner: 20)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.snappy, value: waiting.count)
    }

    private var headline: String {
        if !waiting.isEmpty {
            return waiting.count == 1 ? "A booking changed" : "\(waiting.count) bookings changed"
        }
        return applied.count == 1 ? "A booking was updated for you" : "\(applied.count) bookings updated for you"
    }

    /// The first one, named — "Flight 6E 5307 was rescheduled · Kashi".
    private var detail: String {
        guard let first = waiting.first ?? applied.first else { return "" }
        let trip = store.trip(first.tripID)
        let item = trip?.items.first { $0.id == first.itemID }
        let name = first.needsChoice
            ? "Tap to say which booking"
            : first.headline(for: item ?? first.before?.item, tripCurrency: trip?.currencyCode ?? "INR")
        return [name, trip?.title].compactMap { $0 }.joined(separator: " · ")
    }
}
