//
//  SettlementReviewSheet.swift
//  Equitrip
//

import SwiftUI

/// The recipient's side: somebody says they paid you. Say whether they did.
///
/// Two answers, and both of them move the ledger — that's what makes this
/// different from reading a notification. Confirming clears the balance for
/// good; declining hands it straight back to the suggested-transfers list so
/// the payer can try again, with the method or the amount corrected.
struct SettlementReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    let trip: Trip
    let settlement: Settlement

    @State private var receipt: ReceiptRef?
    @State private var isResponding = false

    private var payer: Traveller? { trip.traveller(settlement.fromID) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    claim
                    details
                    if let proofURL = settlement.proofURL { proof(proofURL) }
                    Color.clear.frame(height: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            if settlement.isPending {
                footer
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .presentationBackground { CanvasBackground() }
        .fullScreenCover(item: $receipt) { ref in
            ReceiptPreview(url: ref.url, caption: "\(payer?.name ?? "They") · proof of payment")
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settlement request")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(trip.title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Claim

    private var claim: some View {
        VStack(spacing: 14) {
            if let payer {
                TravellerAvatar(traveller: payer, size: 64)
            }

            VStack(spacing: 3) {
                Text("\(payer?.name ?? "Someone") says they paid you")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)

                Text(Money.format(settlement.amount, code: settlement.currencyCode))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }

            if !settlement.isPending {
                TagChip(
                    title: settlement.status.label,
                    tint: settlement.status.tint,
                    symbol: settlement.status.symbol
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .cardSurface(corner: 24)
    }

    // MARK: - Details

    private var details: some View {
        VStack(spacing: 0) {
            detailRow(label: "Method", value: settlement.method.label, symbol: settlement.method.symbol)

            if !settlement.note.isEmpty {
                Hairline(inset: 16)
                detailRow(label: "Note", value: settlement.note, symbol: "text.alignleft")
            }

            Hairline(inset: 16)
            detailRow(
                label: "Sent",
                value: settlement.createdAt.formatted(date: .abbreviated, time: .shortened),
                symbol: "clock"
            )
        }
        .cardSurface(corner: 20)
    }

    private func detailRow(label: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: symbol, tint: AppTheme.inkSecondary, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Proof

    private func proof(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROOF OF PAYMENT")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            Button { receipt = ReceiptRef(url: url) } label: {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: Color.black.opacity(0.04)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - Footer

    /// Confirm and Decline read as equal-weight answers, the same balance the
    /// itinerary payment card already strikes — a dispute here is often just
    /// "wrong amount", not an accusation.
    private var footer: some View {
        VStack(spacing: 0) {
            Hairline()

            SlideToRespond(
                onConfirm: { respond(.confirmed) },
                onDecline: { respond(.declined) }
            )
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 22)
            .allowsHitTesting(!isResponding)
        }
        .background(.ultraThinMaterial)
    }

    private func respond(_ status: Settlement.Status) {
        isResponding = true
        // The slide itself already gave the haptic and the landing animation
        // — firing another here on top would double up the confirmation.
        store.respondToSettlement(settlement, with: status, in: trip.id)
        Task { @MainActor in
            try? await Task.sleep(for: SlideToRespond.landingHold)
            dismiss()
        }
    }
}
