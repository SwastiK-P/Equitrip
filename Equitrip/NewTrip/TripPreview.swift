//
//  TripPreview.swift
//  Equitrip
//

import SwiftUI

/// A trip you're not on yet, and the decision about whether to be.
///
/// One view for both ways that happens — you typed a code or scanned a QR, or
/// somebody asked you — because it is one question. The trip, its dates, what
/// it has cost so far and who's already going are the facts you'd want either
/// way, and the only real difference is whether there's a name attached to the
/// asking and whether "no" is an answer worth offering. Those are a chip and a
/// button; they don't warrant a second screen.
///
/// Everything shown here is readable *before* joining, and nothing else is.
/// `bookingCount` and `projectedCost` come from a server-side aggregate rather
/// than from `items`, because row-level security correctly hides the itinerary
/// from somebody who isn't a member — reading the list directly returned empty
/// every time and previewed a fully planned trip as "0 bookings · ₹0".
struct TripPreview: View {
    /// How the person got here. Changes two things and nothing else.
    enum Source {
        /// Typed a code or scanned a QR. They went looking, so there's nobody
        /// to credit and declining is just closing the screen.
        case code
        /// Somebody asked. Worth naming, and worth being able to refuse.
        case invitation(from: Traveller?)

        var inviter: Traveller? {
            if case let .invitation(from) = self { return from }
            return nil
        }

        var isInvitation: Bool {
            if case .invitation = self { return true }
            return false
        }
    }

    let trip: Trip
    var source: Source = .code
    /// A join in flight. Covers both the write and the re-sync behind it.
    var isWorking: Bool = false
    /// Joined, and showing so. The one state that replaces the action block
    /// rather than disabling it.
    var isJoined: Bool = false

    var onJoin: () -> Void
    /// Offered only when somebody asked. Nil on the code path, where the
    /// answer to "no" is the close button you already have.
    var onDecline: (() -> Void)?
    var onDone: (() -> Void)?

    @State private var showTravellers = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    figures
                    TravellerSummaryRow(
                        // The people actually going. Anybody else who's been
                        // asked and hasn't answered isn't part of that count
                        // yet — they show as invited inside the roster sheet,
                        // which is the right level of detail for a fact that
                        // specific.
                        travellers: trip.activeTravellers,
                        organisers: trip.organisers
                    ) {
                        showTravellers = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            // Pinned, not scrolled. The decision is the point of the screen
            // and it shouldn't be something you have to reach for — and on a
            // trip with a long name or a wrapped destination the button was
            // landing below the fold.
            footer
        }
        .sheet(isPresented: $showTravellers) {
            // Read-only: you can see who's coming before you commit, but
            // you're not on the trip and have no business editing its roster.
            TravellerPickerSheet(
                travellers: .constant(trip.travellers),
                organiserIDs: .constant(trip.organiserIDs),
                isEditable: false,
                trip: trip
            )
        }
    }

    // MARK: - Hero

    /// The photograph, with the trip's identity on it and the asking above it.
    ///
    /// Two overlays, deliberately at opposite corners. The title block sits
    /// where every other hero in the app puts it; the invitation chip takes the
    /// empty top corner rather than stacking above the title, which would push
    /// the name of the trip down into the gradient and make the person who
    /// invited you louder than the place you'd be going.
    private var hero: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint
        )
        .frame(height: 190)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                .frame(height: 110)
        }
        .overlay(alignment: .topLeading) { invitedChip }
        .overlay(alignment: .bottomLeading) { title }
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var invitedChip: some View {
        if source.isInvitation {
            HStack(spacing: 6) {
                if let inviter = source.inviter {
                    TravellerAvatar(traveller: inviter, size: 20)
                } else {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                }

                Text(source.inviter.map { "\($0.name) invited you" } ?? "You've been invited")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
            }
            .padding(.leading, source.inviter == nil ? 10 : 5)
            .padding(.trailing, 10)
            .padding(.vertical, 5)
            // The same glass capsule the trip cards float over their
            // photographs, so a chip on an image reads the same way everywhere.
            .glassEffect(.regular.tint(.white.opacity(0.55)), in: .capsule)
            .padding(12)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(trip.title)
                .font(AppTheme.display(24))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(trip.dateRange) · \(trip.destination.isEmpty ? "Destination not set" : trip.destination)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
        .padding(16)
    }

    // MARK: - Figures

    private var figures: some View {
        HStack(spacing: 0) {
            cell(value: "\(trip.dayCount)", label: trip.dayCount == 1 ? "day" : "days")
            divider
            cell(value: "\(trip.bookingCount)", label: trip.bookingCount == 1 ? "booking" : "bookings")
            divider
            cell(value: trip.projectedLabel, label: "booked so far")
        }
        .padding(.vertical, 15)
        .cardSurface(corner: 20)
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.cardStroke.opacity(0.10)).frame(width: 1, height: 30)
    }

    private func cell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    // MARK: - Action

    /// The action bar, on glass at the bottom of the screen.
    ///
    /// Ordered by weight: the thing most people are here to do, then the
    /// answer some of them need, then the sentence that qualifies both. Small
    /// print sits under the pair rather than between them — a caption wedged
    /// between two buttons reads as belonging to the first one, and this one
    /// is about the decision, not about either button.
    private var footer: some View {
        VStack(spacing: 0) {
            Hairline()

            Group {
                if isJoined { done } else { action }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 22)
        }
        .background(.ultraThinMaterial)
    }

    private var action: some View {
        VStack(spacing: 12) {
            Button(action: onJoin) {
                ZStack {
                    // Held in the layout while loading so the button doesn't
                    // resize under the thumb that's still on it.
                    Text(isWorking ? "Joining…" : "Join this trip")
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(isWorking ? 0 : 1)

                    if isWorking {
                        ProgressView().controlSize(.small).tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.accent)
            .disabled(isWorking)

            if let onDecline {
                Button(action: onDecline) {
                    Text("No thanks")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isWorking)
            }

            Text(smallPrint)
                .font(.system(size: 11.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }

    /// The one sentence that makes this an informed decision. Joining a trip is
    /// agreeing to share what the group spends on it, and that belongs next to
    /// the button rather than in a coloured box further up the screen.
    private var smallPrint: String {
        source.isInvitation
            ? "You'll start sharing what the group books, and you'll see the itinerary, ledger and chat. Nothing lands on you while this is unanswered."
            : "You'll be added as a traveller. Nothing is charged to you until you're put on a booking."
    }

    /// What the action bar becomes once you're on the trip.
    ///
    /// Compact on purpose — it's a pinned bar, not a results screen, and the
    /// celebration is a tick and a sentence rather than a panel. The bar keeps
    /// the same height it had a moment ago, so the trip behind it doesn't jump.
    private var done: some View {
        VStack(spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.positive)

                Text("You're on the trip")
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            }
            .transition(.scale.combined(with: .opacity))

            if let onDone {
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
            }

            Text("Everyone already on \(trip.title) gets a notification, and shares recalculate to include you.")
                .font(.system(size: 11.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }
}
