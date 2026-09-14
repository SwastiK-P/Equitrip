//
//  DetectedExpensesSheet.swift
//  Equitrip
//

import SwiftUI

/// The payments the app found, waiting to be told what they were.
///
/// A queue rather than a feed. Everything on it is a question — is this the
/// trip's, and who was in on it — and a question that stays answered once
/// answered. So the list empties as it's worked through, and the two things
/// that aren't questions (payments filed as somebody's own shopping, and
/// payments already dealt with) are folded away underneath rather than
/// competing with the ones that still need a person.
struct DetectedExpensesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store
    @Environment(\.detectedExpenses) private var detections
    @Environment(\.gmailSync) private var sync

    let trip: Trip

    @State private var adding: DetectedExpense?
    @State private var showingSkipped = false
    @State private var showingHandled = false

    private var waiting: [DetectedExpense] { detections.waiting(for: trip.id) }
    private var skipped: [DetectedExpense] { detections.skipped(for: trip.id) }
    private var handled: [DetectedExpense] { detections.settled(for: trip.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let failure = sync?.state.failure {
                    ConnectionBanner(message: failure) {
                        sync?.sync(for: trip, force: true)
                    }
                }

                if waiting.isEmpty {
                    emptyState
                } else {
                    ForEach(waiting) { detection in
                        DetectionCard(
                            detection: detection,
                            add: { adding = detection },
                            dismissDetection: { withAnimation(.snappy) { detections.dismiss(detection.id) } }
                        )
                    }
                }

                if !skipped.isEmpty { skippedSection }
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
        .refreshable { sync?.sync(for: trip, force: true) }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .sheet(item: $adding) { detection in
            QuickAddSheet(
                travellers: trip.travellers,
                currencyCode: detection.currencyCode,
                day: Calendar.current.startOfDay(for: detection.receivedAt),
                seed: seed(for: detection),
                onSave: { item in
                    store.addItem(item, to: trip.id)
                    detections.markAdded(detection.id, as: item.id)
                },
                // The detailed editor doesn't take a seed the way quick add
                // does, and reaching it from here would need a third sheet on
                // top of two. Quick add is the right shape for this anyway:
                // everything the editor asks for extra is already known.
                onSwitchToDetailed: { _ in }
            )
        }
    }

    /// The money and the clock, handed over. The title is deliberately left
    /// blank whenever the mail only gave a UPI handle — see
    /// `DetectedExpense.suggestedTitle`.
    private func seed(for detection: DetectedExpense) -> QuickAddSheet.Seed {
        QuickAddSheet.Seed(
            // Never pre-filled: the one thing a bank email cannot know is what
            // the money was for. The payee is offered as a chip instead.
            title: "",
            vendor: detection.suggestion,
            amount: detection.amount,
            paidAt: detection.receivedAt,
            paymentMethod: detection.channel.paymentMethod,
            provenance: detection.fullProvenance
        )
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Spotted in your mail")
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
        if case .syncing(let read, let total) = sync?.state, total > 0 {
            return "Reading \(total) \(total == 1 ? "message" : "messages")… \(read) done"
        }
        if waiting.isEmpty { return trip.title }
        return "\(waiting.count) waiting on \(trip.title)"
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 10) {
            IconTile(symbol: "tray", size: 44, corner: 14)

            Text(GmailAccount.shared.isActive ? "Nothing waiting" : "Gmail isn't connected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(
                GmailAccount.shared.isActive
                    ? "Payment alerts that arrive while \(trip.title) is running will show up here."
                    : "Connect Gmail in your profile settings to have payment alerts read as you go."
            )
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.inkSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .cardSurface(corner: 22)
    }

    // MARK: - Folded away

    /// Payments the reader decided were somebody's own online shopping.
    ///
    /// Kept visible, because the classifier will occasionally be wrong about a
    /// hotel booked through a travel site, and a bucket you can't see into is
    /// indistinguishable from a payment that was never detected.
    private var skippedSection: some View {
        disclosure(
            title: "Not on this trip",
            count: skipped.count,
            isOpen: $showingSkipped
        ) {
            ForEach(skipped) { detection in
                DetectionCard(
                    detection: detection,
                    add: { withAnimation(.snappy) { detections.markOnTrip(detection.id) } },
                    addTitle: "It is on the trip",
                    dismissDetection: { withAnimation(.snappy) { detections.dismiss(detection.id) } }
                )
            }
        }
    }

    private var handledSection: some View {
        disclosure(
            title: "Handled",
            count: handled.count,
            isOpen: $showingHandled
        ) {
            ForEach(handled) { detection in
                HStack(spacing: 12) {
                    Image(systemName: detection.status == .waiting ? "circle" : (isAdded(detection) ? "checkmark.circle.fill" : "xmark.circle.fill"))
                        .font(.system(size: 17))
                        .foregroundStyle(isAdded(detection) ? AppTheme.positive : AppTheme.inkTertiary)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(Money.format(detection.amount, code: detection.currencyCode))
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("\(detection.dayText), \(detection.clockText) · \(isAdded(detection) ? "added" : "not an expense")")
                            .font(.system(size: 11.5))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }

                    Spacer(minLength: 6)

                    if !isAdded(detection) {
                        Button("Undo") { withAnimation(.snappy) { detections.restore(detection.id) } }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .cardSurface(corner: 18)
            }
        }
    }

    private func isAdded(_ detection: DetectedExpense) -> Bool {
        if case .added = detection.status { return true }
        return false
    }

    private func disclosure<Content: View>(
        title: String,
        count: Int,
        isOpen: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy) { isOpen.wrappedValue.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("\(title) · \(count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .rotationEffect(.degrees(isOpen.wrappedValue ? 90 : 0))

                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())

            if isOpen.wrappedValue { content() }
        }
        .padding(.top, 8)
    }
}

// MARK: - Card

/// One detected payment: the money, when it happened, and the two answers.
private struct DetectionCard: View {
    let detection: DetectedExpense
    var add: () -> Void
    var addTitle: String = "Add to trip"
    var dismissDetection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(symbol: detection.channel.symbol, size: 38, corner: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Money.format(detection.amount, code: detection.currencyCode))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(headline)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(detection.clockText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(detection.dayText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }

            HStack(spacing: 7) {
                GmailMark().frame(width: 15, height: 11)

                Text(detection.provenance)
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                // Said out loud rather than hidden behind a colour: the model
                // and the email agreed on this figure, or they didn't.
                if detection.confidence == .likely {
                    Label("check the amount", systemImage: "exclamationmark.circle")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSecondary)
                }
            }

            // The same pair as Confirm/Dispute in the notification feed.
            //
            // Flat rounded rectangles, not glass and not capsules: the glass
            // styles carry their own blur and floating shadow, which on a list
            // of these read as two more surfaces stacked on the card already
            // under them. Equal widths because these are two answers to one
            // question, and the primary sits on the right, which is where the
            // notification card already taught the hand to look for it.
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismissDetection()
                } label: {
                    actionLabel(symbol: "xmark", title: "Not an expense", tint: AppTheme.inkSecondary)
                        .background(AppTheme.card.opacity(0.7), in: .rect(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                        }
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    add()
                } label: {
                    actionLabel(symbol: "plus", title: addTitle, tint: AppTheme.ctaLabel)
                        .background(AppTheme.accent, in: .rect(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 2)
        }
        .padding(14)
        .cardSurface(corner: 22)
    }

    private func actionLabel(symbol: String, title: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 13.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .contentShape(.rect(cornerRadius: 12, style: .continuous))
    }

    /// What it was paid to, when the mail said — and the subject when it
    /// didn't, because "HDFC Bank alert" is still more use than a blank line.
    private var headline: String {
        if !detection.payee.isEmpty { return "to \(detection.payee)" }
        return detection.subject.isEmpty ? detection.sender : detection.subject
    }
}
