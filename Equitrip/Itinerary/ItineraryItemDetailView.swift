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
    /// Reports a payment as wrong — passes an optional reason string. The
    /// only way a payment's status ever changes once it's recorded: it's
    /// taken as confirmed the moment someone says they paid, and this is
    /// how anyone who disagrees says otherwise.
    var onDisputePayment: ((String?) -> Void)?
    /// Mark the active dispute as resolved.
    var onResolveDispute: (() -> Void)?

    @State private var showParticipants = false
    @State private var showPayment = false
    @State private var payerDraft: UUID?
    @State private var methodDraft: PaymentMethod?
    @State private var receiptDraft: URL?
    /// Whether the payment row is showing its receipt.
    @State private var showsReceipt = false
    /// The receipt being viewed full screen.
    @State private var previewing: ReceiptRef?
    /// Presenting the "Enter dispute reason" sheet.
    @State private var showDisputeEntry = false
    /// The dispute reason typed by the user.
    @State private var disputeReasonDraft = ""

    private var participants: [Traveller] { trip.participants(of: item) }
    private var shares: [(traveller: Traveller, amount: Double)] { trip.shares(of: item) }

    /// Same test as `TimelineRow`'s dashed card border — logged after the
    /// trip had already started, rather than planned ahead with the rest of
    /// the itinerary.
    private var isUnplanned: Bool { item.createdAt >= trip.startDate }

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
                    // Payer first, sharing second. The two answer "whose money
                    // was this?" and "whose cost is it?", and they only make
                    // sense in that order — the split divides a sum somebody
                    // has already handed over, so reading the division before
                    // knowing whether anyone paid is reading the second half of
                    // a sentence first.
                    paidBy
                    costBreakdown
                }

                // Dispute card sits after cost info, before participants.
                // It belongs in the money section because it's about the
                // payment record, not the booking plan.
                if item.isDisputed {
                    disputeCard
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
        // "Who paid for this?" — see `OnscreenEntities`.
        .onscreenBooking(item)
        .sheet(isPresented: $showParticipants) {
            ParticipantPickerSheet(
                travellers: trip.travellers,
                shareEach: shares.first?.amount,
                currencyCode: trip.currencyCode
            )
        }
        .fullScreenCover(item: $previewing) { receipt in
            ReceiptPreview(url: receipt.url, caption: receiptCaption)
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
        .sheet(isPresented: $showDisputeEntry) {
            DisputeReasonSheet(reason: $disputeReasonDraft) {
                onDisputePayment?(disputeReasonDraft.trimmingCharacters(in: .whitespaces).isEmpty ? nil : disputeReasonDraft)
                showDisputeEntry = false
                GlassToastCenter.shared.show(.init(
                    symbol: "flag.fill",
                    tint: AppTheme.danger,
                    title: "Payment reported",
                    subtitle: "\"\(item.title)\" is flagged until it's sorted out.",
                    duration: .seconds(3.5)
                ))
            }
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
        GlassToastCenter.shared.show(.init(
            symbol: "creditcard.fill",
            tint: AppTheme.accent,
            title: "Payment recorded",
            subtitle: "\"\(item.title)\" now shows who paid.",
            duration: .seconds(3)
        ))
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

            if isUnplanned {
                Text("Unplanned")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .overlay {
                        Capsule().strokeBorder(AppTheme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1.3, dash: [4, 3]))
                    }
            }

            Spacer(minLength: 8)

            // Reporting only makes sense once there's a payment to question,
            // and only once — a payment already under dispute is reported,
            // not reportable again.
            if onDisputePayment != nil, item.paidByID != nil, !item.isDisputed {
                smallActionButton(title: "Report", symbol: "flag", tint: AppTheme.danger) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    disputeReasonDraft = ""
                    showDisputeEntry = true
                }
            }

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

                    // Trimmed, not just non-empty. A vendor of " " passes
                    // `isEmpty` and renders as a blank line under the title —
                    // a gap where a name should be, which reads as something
                    // failing to load rather than as nothing to show.
                    if let vendor = item.vendorName {
                        Text(vendor)
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

                // Per person — but only where the people differ.
                //
                // Under an equal split every row carries the same number, and
                // three identical lines of "₹466.67" don't answer a question
                // anybody had; they just make you read three times to learn
                // one thing. Where the shares actually vary — by participant,
                // exact amounts, one person carrying it — the list is the
                // whole point, because what *you* owe is the thing people
                // arrive at this screen to check.
                if item.split == .equal {
                    Hairline(inset: 16)
                    evenShare
                } else {
                    ForEach(shares, id: \.traveller.id) { entry in
                        Hairline(inset: 16)
                        shareRow(entry.traveller, entry.amount)
                    }
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

    /// The collapsed form: one line, everybody's faces, one figure.
    @ViewBuilder
    private var evenShare: some View {
        if !shares.isEmpty {
            let each = Money.wholeShare(of: item.cost, heads: shares.count)
            HStack(spacing: 12) {
                AvatarStack(travellers: shares.map(\.traveller), size: 28, max: 5)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(Money.format(each, code: trip.currencyCode)) each")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)

                    Text("across \(shares.count.pluralised("person", "people")) on the trip")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func shareRow(_ traveller: Traveller, _ amount: Double) -> some View {
        let isYou = traveller.id == Traveller.you.id

        return HStack(spacing: 12) {
            TravellerAvatar(traveller: traveller, size: 30)

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

    /// Whose money it was.
    ///
    /// Open to everyone, not just organisers — the person who paid for dinner
    /// is rarely the person who organised the trip.
    ///
    /// The row discloses rather than navigating. The receipt used to hang
    /// underneath permanently, which put a photograph of a restaurant bill in
    /// the middle of the booking whether anyone wanted it or not, and made the
    /// section taller than everything else on the screen. It's evidence, and
    /// evidence should be one tap away rather than always on display. Tapping
    /// the row itself no longer opens the payment editor either: that was a
    /// destination hiding behind a row that looked like a summary, and it meant
    /// there was no way to *look* at a payment without being taken somewhere to
    /// change it.
    private var paidBy: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Paid by")

            VStack(spacing: 0) {
                if item.paidByID == nil {
                    unpaidRow
                } else {
                    payerRow

                    if showsReceipt {
                        Hairline(inset: 16)
                        receiptPanel
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            // Clip the *content*, then lay the card surface behind it.
            //
            // The other way round — `.cardSurface` then `.clipped()` — was
            // clipping the surface's own shadow to the card's bounds, which
            // turned a soft lift into a hard-edged grey box drawn tight around
            // the card, and did the same to the glass button inside it. The
            // clip is only here to stop the receipt panel spilling past the
            // rounded corners as it expands, so it belongs on the thing that
            // expands rather than on everything.
            .clipShape(.rect(cornerRadius: 20, style: .continuous))
            .cardSurface(corner: 20)
        }
    }

    /// Nothing recorded yet — so the row is the call to action it looks like.
    private var unpaidRow: some View {
        Button {
            guard onRecordPayment != nil else { return }
            openPayment()
        } label: {
            HStack(spacing: 12) {
                SymbolBadge(symbol: "creditcard", tint: AppTheme.accent, size: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Nobody's paid yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.ink)

                    Text(onRecordPayment == nil ? "Not recorded" : "Tap to record who did")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
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
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(onRecordPayment == nil)
    }

    private var payerRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                showsReceipt.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                if let payer = item.paidByID.flatMap(trip.traveller) {
                    TravellerAvatar(traveller: payer, size: 34)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(payer.id == Traveller.you.id ? "You paid" : "\(payer.name) paid")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)

                        Text(methodLine)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }

                Spacer(minLength: 6)

                Text(Money.format(item.cost, code: trip.currencyCode))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .rotationEffect(.degrees(showsReceipt ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(showsReceipt ? "Hide payment details" : "Show payment details")
    }

    /// What's behind the arrow: the receipt if there is one, the fact that
    /// there isn't if there isn't, and the way to change either.
    private var receiptPanel: some View {
        VStack(spacing: 12) {
            if let receipt = item.receiptURL {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    previewing = ReceiptRef(url: receipt)
                } label: {
                    AsyncImage(url: receipt, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()

                        case .failure:
                            receiptPlaceholder(symbol: "exclamationmark.triangle", text: "Couldn't load it")

                        default:
                            receiptPlaceholder(symbol: "doc.text.image", text: "Loading…")
                        }
                    }
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                    }
                    // A photographed bill is usually unreadable at this size,
                    // so the affordance says so rather than leaving people to
                    // discover that it's tappable.
                    .overlay(alignment: .bottomTrailing) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("Tap to read")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.45), in: .capsule)
                        .padding(10)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)

                    Text(
                        item.paymentMethod?.isOnline == false
                            ? "Cash — nothing to attach."
                            : "No receipt attached."
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
            }

            if onRecordPayment != nil {
                smallActionButton(
                    title: item.receiptURL == nil ? "Edit payment" : "Change payment",
                    symbol: "pencil",
                    tint: AppTheme.accent,
                    action: openPayment
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 13)
        .padding(.bottom, 14)
    }

    /// A small, content-sized action rather than a full-width `.glass`
    /// button — voting and editing a recorded payment are quick, low-stakes
    /// taps here, not "are you sure" moments, and stretching them the width
    /// of the card overstated that.
    private func smallActionButton(
        title: String,
        symbol: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint.opacity(0.13), in: .rect(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func receiptPlaceholder(symbol: String, text: String) -> some View {
        ZStack {
            AppTheme.canvasBottom.opacity(0.5)

            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .light))
                Text(text)
                    .font(.system(size: 12.5))
            }
            .foregroundStyle(AppTheme.inkTertiary)
        }
    }

    private func openPayment() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        payerDraft = item.paidByID
        methodDraft = item.paymentMethod
        receiptDraft = item.receiptURL
        showPayment = true
    }

    /// Read under the receipt when it's open full screen, so the image can be
    /// checked against the claim without going back for it.
    private var receiptCaption: String {
        let payer = item.paidByID.flatMap(trip.traveller)
        let name = payer.map { $0.id == Traveller.you.id ? "You" : $0.name } ?? "Someone"
        let method = item.paymentMethod.map { " · \($0.label)" } ?? ""
        return "\(name) paid \(Money.format(item.cost, code: trip.currencyCode))\(method)"
    }

    private var methodLine: String {
        guard let method = item.paymentMethod else { return "Method not recorded" }
        return item.receiptURL == nil ? method.label : "\(method.label) · receipt attached"
    }

    private var disputeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.danger.opacity(0.13), in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Disputed")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(disputeLine)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if let reason = disputeReason {
                Text(reason)
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.canvasBottom.opacity(0.45), in: .rect(cornerRadius: 14, style: .continuous))
            }

            if let onResolveDispute {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onResolveDispute()
                    GlassToastCenter.shared.show(.init(
                        symbol: "checkmark.seal.fill",
                        tint: AppTheme.positive,
                        title: "Dispute resolved",
                        subtitle: "\"\(item.title)\" is settled.",
                        duration: .seconds(3)
                    ))
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Dispute resolved")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.positive)
            }
        }
        .padding(16)
        .background(AppTheme.danger.opacity(0.07), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.danger.opacity(0.22))
        }
    }

    private var disputeLine: String {
        let actor = item.disputedByID.flatMap(trip.traveller)
        let name = actor.map { $0.id == Traveller.you.id ? "You" : $0.name } ?? "Someone"
        guard let date = item.disputedAt else { return "\(name) disputed this payment." }
        return "\(name) disputed this payment \(DateFormatter.cached("d MMM, h:mm a").string(from: date))."
    }

    private var disputeReason: String? {
        guard let reason = item.disputeReason?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reason.isEmpty
        else { return nil }
        return reason
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
                TravellerAvatar(traveller: creator, size: 26)

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

private struct DisputeReasonSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var reason: String
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.9)
                        .foregroundStyle(AppTheme.inkTertiary)

                    TextField("Amount doesn't match receipt", text: $reason, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(3...5)
                        .padding(14)
                        .background(AppTheme.card.opacity(0.76), in: .rect(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                        }
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSubmit()
                    dismiss()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Dispute payment")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.danger)

                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Spacer(minLength: 0)
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium])
        .presentationBackground { CanvasBackground() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dispute payment")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("Add a short note for the trip.")
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
}
