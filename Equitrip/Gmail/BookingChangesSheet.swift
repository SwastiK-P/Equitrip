//
//  BookingChangesSheet.swift
//  Equitrip
//

import SwiftUI

/// Booking changes read out of the mail, each waiting for a yes or a no.
///
/// A queue, like `DetectedExpensesSheet`: it empties as it's answered, and
/// what's been answered folds away underneath with an Undo, because applying
/// a change edits a booking the whole group sees and has to be as easy to
/// take back as it was to make.
///
/// A card that's been confirmed stays where it is until the sheet closes, so
/// its steps can finish ticking rather than vanishing mid-way.
struct BookingChangesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store
    @Environment(\.bookingChanges) private var changes
    @Environment(\.bookingChangeSync) private var sync

    /// Only this trip's changes, when opened from a trip.
    var tripID: UUID?

    @State private var showingHandled = false
    /// Acted on in this sheet, kept on screen until it closes.
    @State private var actedOn: [String] = []

    private var waiting: [BookingChange] {
        let live = changes.waiting(for: tripID)
        let kept = actedOn.compactMap { changes.change($0) }.filter { !$0.status.isWaiting }
        return (live + kept).sorted { $0.receivedAt > $1.receivedAt }
    }
    private var handled: [BookingChange] { changes.handled(for: tripID).filter { !actedOn.contains($0.id) } }

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let failure = sync?.state.failure {
                        ConnectionBanner(message: failure) { sync?.sync(force: true) }
                    }

                    if waiting.isEmpty {
                        emptyState
                    } else {
                        ForEach(waiting) { change in
                            BookingChangeCard(
                                change: change,
                                dismissTitle: "Ignore",
                                apply: {
                                    actedOn.append(change.id)
                                    apply(change)
                                },
                                undo: {
                                    if let updated = changes.change(change.id) {
                                        BookingChangeApplier.undo(updated, store: store, changes: changes)
                                    }
                                },
                                dismissChange: { withAnimation(.snappy) { changes.dismiss(change.id) } },
                                choose: { candidate in withAnimation(.snappy) { changes.choose(candidate, for: change.id) } },
                                finished: { withAnimation(.snappy) { actedOn.removeAll { $0 == change.id } } }
                            )
                            .id(change.id)
                        }
                    }

                    if !handled.isEmpty { handledSection }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .refreshable { sync?.sync(force: true) }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onAppear { changes.markAllSeen() }
    }

    private func apply(_ change: BookingChange) {
        BookingChangeApplier.apply(change, store: store, changes: changes, postToChat: sync?.postsToChat ?? true)
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Booking changes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var subtitle: String {
        if sync?.state.isSyncing == true { return "Checking your mail…" }
        if waiting.isEmpty { return tripID.flatMap { store.trip($0)?.title } ?? "Cancellations and reschedules" }
        return "\(waiting.count) waiting"
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 10) {
            IconTile(symbol: "calendar.badge.checkmark", size: 44, corner: 14)

            Text("Nothing has changed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(emptyDetail)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .cardSurface(corner: 22)
    }

    private var emptyDetail: String {
        guard GmailAccount.shared.isActive, sync?.isEnabled == true else {
            return "Connect Gmail in your profile to have cancellations and reschedules from airlines, hotels and tour operators picked up for you."
        }
        return "When an airline, hotel or tour operator emails a cancellation or a new time for one of your bookings, it shows up here."
    }

    // MARK: - Handled

    private var handledSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy) { showingHandled.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("Handled · \(handled.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .rotationEffect(.degrees(showingHandled ? 90 : 0))
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())

            if showingHandled {
                ForEach(handled) { change in handledRow(change) }
            }
        }
        .padding(.top, 8)
    }

    private func handledRow(_ change: BookingChange) -> some View {
        let trip = store.trip(change.tripID)
        let name = change.before?.title ?? trip?.items.first { $0.id == change.itemID }?.title ?? "A booking"
        let applied = change.status.wasApplied

        return HStack(spacing: 12) {
            Image(systemName: applied ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 17))
                .foregroundStyle(applied ? AppTheme.positive : AppTheme.inkTertiary)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text([trip?.title, change.status.wasAutomatic ? "applied automatically" : (applied ? "applied" : "ignored"), change.dayText]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            Button(applied ? "Undo" : "Restore") {
                withAnimation(.snappy) {
                    if applied {
                        BookingChangeApplier.undo(change, store: store, changes: changes)
                    } else {
                        changes.restore(change.id)
                    }
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.accent)
            .buttonStyle(PressableButtonStyle())
            .disabled(applied && change.before == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cardSurface(corner: 18)
    }
}
