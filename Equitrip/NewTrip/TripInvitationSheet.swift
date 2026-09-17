//
//  TripInvitationSheet.swift
//  Equitrip
//

import SwiftUI

// MARK: - Home card

/// "Priya invited you to Goa", on Home.
///
/// Built to the same pattern as `PendingSettlementsCard`, because it is the
/// same kind of thing: a short list of things somebody else is waiting on you
/// to answer. Tinted label above a plain card, a person's face on each row, a
/// Review capsule on the right. Nothing about an invitation warrants a
/// different shape from a settlement request, and giving it one would only
/// make Home look like two apps.
struct TripInvitationsCard: View {
    let invitations: [TripInvitation]
    var onOpen: (TripInvitation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accent)

                Text(invitations.count == 1 ? "You've been invited" : "\(invitations.count) invitations")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 0) {
                ForEach(Array(invitations.enumerated()), id: \.element.id) { index, invitation in
                    Button { onOpen(invitation) } label: { row(invitation) }
                        .buttonStyle(PressableButtonStyle())

                    if index < invitations.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 20)
        }
    }

    /// The inviter's face, not an envelope glyph.
    ///
    /// An invitation comes from a person, and the row people scan on Home is
    /// the one with a face they recognise on it. Falls back to the trip's own
    /// symbol when we don't know who asked — an invitation with no name is
    /// still an invitation.
    private func row(_ invitation: TripInvitation) -> some View {
        let trip = invitation.trip

        return HStack(spacing: 12) {
            if let inviter = invitation.inviter {
                TravellerAvatar(traveller: inviter, size: 38)
            } else {
                SymbolBadge(symbol: trip.symbol, tint: AppTheme.accent, size: 38)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(invitation.invitedByName.map { "\($0) invited you to \(trip.title)" }
                     ?? "You're invited to \(trip.title)")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(trip.destination.isEmpty ? "Destination not set" : trip.destination) · \(invitation.when)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("Review")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.ctaLabel)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(AppTheme.cta, in: .capsule)
        }
        .padding(13)
    }
}

// MARK: - The sheet

/// An invitation, opened.
///
/// Almost nothing of its own: the screen is `TripPreview`, the same one the
/// code and QR paths land on, because it answers the same question. This adds
/// the chrome a sheet needs, the decline confirmation, and the wiring to say
/// yes or no. If the two screens ever diverge it should be here, in twenty
/// lines, rather than in two parallel layouts drifting apart.
struct TripInvitationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    let invitation: TripInvitation

    @State private var isWorking = false
    @State private var isJoined = false
    @State private var showDecline = false

    var body: some View {
        ZStack {
            CanvasBackground()

            TripPreview(
                trip: invitation.trip,
                source: .invitation(from: invitation.inviter),
                isWorking: isWorking,
                isJoined: isJoined,
                onJoin: { respond(accept: true) },
                // Withdrawn once you've joined — there is nothing left to
                // decline, and the block it sits in has been replaced anyway.
                onDecline: isJoined ? nil : { showDecline = true },
                onDone: { dismiss() }
            )
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .presentationBackground { CanvasBackground() }
        .confirmationDialog(
            "Decline \(invitation.trip.title)?",
            isPresented: $showDecline,
            titleVisibility: .visible
        ) {
            Button("Decline invitation", role: .destructive) { respond(accept: false) }
            Button("Keep it for now", role: .cancel) {}
        } message: {
            Text("The invitation goes away and you won't be on the trip. \(invitation.invitedByName ?? "Whoever invited you") can always ask again.")
        }
    }

    /// Centred on the close button rather than baseline-aligned to it.
    ///
    /// `.firstTextBaseline` lines the title's baseline up with the glyph's,
    /// which on a 36pt circle sits the disc noticeably low and leaves the row
    /// looking like it fell. The two are a title and a control, not two runs of
    /// text, so they centre on each other.
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(isJoined ? "You're in" : "You're invited")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .contentTransition(.opacity)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            CircleGlyphButton(symbol: "xmark", size: 36) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private func respond(accept: Bool) {
        guard !isWorking else { return }
        isWorking = true

        Task {
            let ok = await store.respondToInvitation(invitation, accept: accept)
            isWorking = false

            guard ok else { return }
            UINotificationFeedbackGenerator().notificationOccurred(accept ? .success : .warning)

            // Accepting earns the confirmation the code path already shows —
            // you're on a trip now, and the screen should say so before it
            // goes. Declining has nothing to confirm.
            if accept {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { isJoined = true }
            } else {
                dismiss()
            }
        }
    }
}
