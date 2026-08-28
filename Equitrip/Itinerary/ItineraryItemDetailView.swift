//
//  ItineraryItemDetailView.swift
//  Equitrip
//

import SwiftUI

/// One booking, in full.
///
/// Tapping a timeline row used to drop straight into the editor, which meant
/// everyone who only wanted to *look* at a booking landed in a form — and
/// non-organisers, who can't edit at all, had nowhere to go. This is the
/// read view: what it is, who's on it, what it costs each of them, and who
/// put it there. Editing is one deliberate tap further, for those who can.
struct ItineraryItemDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let item: ItineraryItem
    let trip: Trip
    /// Recording a payment is not editing the booking, so it's offered to
    /// anyone who can see it — the person who actually paid is usually not the
    /// person who organised the trip.
    var onRecordPayment: ((UUID?, PaymentMethod?, URL?) -> Void)?
    var onEdit: (() -> Void)?

    @State private var showParticipants = false
    @State private var showPayment = false
    @State private var payerDraft: UUID?
    @State private var methodDraft: PaymentMethod?
    @State private var receiptDraft: URL?

    private var participants: [Traveller] { trip.participants(of: item) }
    private var shares: [(traveller: Traveller, amount: Double)] { trip.shares(of: item) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                // Above the money, not below it. On a flight the boarding pass
                // *is* the booking — gate, terminal, and how long you've got —
                // and burying it under the cost breakdown meant scrolling past
                // three cards of arithmetic to find out which airport you're
                // leaving from.
                if let flight = item.flight, flight.isResolved {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Flight details")
                        FlightTicketCard(flight: flight, fallbackDeparture: item.time)
                        FlightRouteMap(flight: flight)
                    }
                }

                facts

                if item.cost > 0 {
                    costBreakdown
                    paidBy
                }

                who
                provenance

                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom) {
            if let onEdit { editBar(onEdit) }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .sheet(isPresented: $showParticipants) {
            ParticipantPickerSheet(
                travellers: trip.travellers,
                shareEach: shares.first?.amount,
                currencyCode: trip.currencyCode
            )
        }
        .sheet(isPresented: $showPayment, onDismiss: commitPayment) {
            PaymentSheet(
                travellers: trip.travellers,
                itemID: item.id,
                cost: item.cost,
                currencyCode: trip.currencyCode,
                paidByID: $payerDraft,
                method: $methodDraft,
                receiptURL: $receiptDraft
            )
        }
    }

    /// The sheet edits copies, and they land on the booking when it closes —
    /// writing through on every tap would put an upsert behind each keystroke
    /// of picking a method.
    private func commitPayment() {
        guard payerDraft != item.paidByID
            || methodDraft != item.paymentMethod
            || receiptDraft != item.receiptURL
        else { return }
        onRecordPayment?(payerDraft, methodDraft, receiptDraft)
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            Text(item.kind.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(item.kind.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.kind.tint.opacity(0.14), in: .capsule)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func editBar(_ action: @escaping () -> Void) -> some View {
        Button {
            // Dismissal is the presenter's job — it owns both sheets and has
            // to sequence them, and calling `dismiss()` here as well raced it.
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                Text("Edit booking")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Sections

    // A stay used to lead with a searched photograph of the hotel. The search
    // was the hotel's name, which returns stock for that string rather than the
    // place the group is checking into, so the picture was decoration at best
    // and wrong at worst.
    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let cover = item.cover {
                AsyncImage(url: cover.url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: AppTheme.card
                    }
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
            }

            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if !item.vendor.isEmpty {
                        Text(item.vendor)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var facts: some View {
        VStack(spacing: 0) {
            factRow(
                symbol: "calendar",
                label: "When",
                value: DateFormatter.cached("EEEE d MMMM").string(from: item.date)
            )

            Hairline(inset: 16)

            factRow(
                symbol: "clock",
                label: "Time",
                value: item.timeLabel ?? "No set time"
            )

            if item.cost > 0 {
                Hairline(inset: 16)
                factRow(
                    symbol: "indianrupeesign.circle",
                    label: "Projected cost",
                    value: Money.format(item.cost, code: trip.currencyCode)
                )
            }
        }
        .cardSurface(corner: 20)
    }

    private func factRow(symbol: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14.5))
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    /// The arithmetic, spelled out. This is the screen someone opens when they
    /// disagree with a number, so it shows the working rather than the result —
    /// the rule, then every person it lands on and what it lands on them for.
    private var costBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Cost sharing")

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: item.split.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.split.label)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text(item.split.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                // Per person, not just "₹2,666.67 each". A single "each"
                // figure is the right number and the wrong answer to the
                // question people actually arrive with, which is what *they*
                // owe — and under "By room" or "Individual" the two aren't the
                // same thing for everybody on the list.
                ForEach(shares, id: \.traveller.id) { entry in
                    Hairline(inset: 16)
                    shareRow(entry.traveller, entry.amount)
                }

                if shares.isEmpty {
                    Hairline(inset: 16)
                    Text("Nobody is being charged for this yet.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                }
            }
            .cardSurface(corner: 20)
        }
    }

    private func shareRow(_ traveller: Traveller, _ amount: Double) -> some View {
        let isYou = traveller.id == Traveller.you.id

        return HStack(spacing: 12) {
            MemojiAvatar(traveller: traveller, size: 30)

            Text(isYou ? "\(traveller.name) (you)" : traveller.name)
                .font(.system(size: 14.5, weight: isYou ? .semibold : .regular))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            Text(Money.format(amount, code: trip.currencyCode))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isYou ? AppTheme.ink : AppTheme.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    /// Whose money it was. Tappable for everyone, not just organisers: the
    /// person who paid for dinner is rarely the person who made the trip.
    private var paidBy: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Paid by")

            Button {
                guard onRecordPayment != nil else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                payerDraft = item.paidByID
                methodDraft = item.paymentMethod
                receiptDraft = item.receiptURL
                showPayment = true
            } label: {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        if let payer = item.paidByID.flatMap(trip.traveller) {
                            MemojiAvatar(traveller: payer, size: 34)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(payer.id == Traveller.you.id ? "You paid" : "\(payer.name) paid")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)

                                Text(methodLine)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }
                        } else {
                            SymbolBadge(symbol: "creditcard", tint: AppTheme.accent, size: 34)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Nobody's paid yet")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)

                                Text(onRecordPayment == nil ? "Not recorded" : "Tap to record who did")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }
                        }

                        Spacer(minLength: 6)

                        if onRecordPayment != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    if let receipt = item.receiptURL {
                        Hairline(inset: 16)

                        AsyncImage(url: receipt) { phase in
                            if case let .success(image) = phase {
                                image.resizable().scaledToFit()
                            } else {
                                Color.clear.frame(height: 80)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 220)
                        .padding(.bottom, 4)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(onRecordPayment == nil)
            .cardSurface(corner: 20)
        }
    }

    private var methodLine: String {
        guard let method = item.paymentMethod else { return "Method not recorded" }
        return item.receiptURL == nil ? method.label : "\(method.label) · receipt attached"
    }

    /// A row rather than a chip wall — the same collapse the booking editor
    /// got, for the same reason: eight faces wrapped onto four rows here and
    /// pushed the flight card and the provenance line off the bottom.
    private var who: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Who's on this · \(participants.count)")

            ParticipantSummaryRow(
                travellers: participants,
                shareEach: shares.first?.amount,
                currencyCode: trip.currencyCode
            ) {
                showParticipants = true
            }
        }
    }

    private var provenance: some View {
        HStack(spacing: 10) {
            if let creator = item.createdByID.flatMap(trip.traveller) {
                MemojiAvatar(traveller: creator, size: 26)

                Text("Added by \(creator.id == Traveller.you.id ? "you" : creator.name)")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
            } else {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkTertiary)

                Text("Added by someone no longer on the trip")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Spacer(minLength: 6)

            Text(DateFormatter.cached("d MMM").string(from: item.createdAt))
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .panelSurface(corner: 16)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(AppTheme.inkTertiary)
            .padding(.leading, 2)
    }
}
