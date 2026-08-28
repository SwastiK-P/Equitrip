//
//  QuickAddSheet.swift
//  Equitrip
//

import SwiftUI

/// Logging something that just happened.
///
/// The full editor asks for a category, a day, a time, a vendor, a photo, a
/// flight number — everything a booking made in advance actually has. Standing
/// on a beach having just paid ₹480 for snacks, all of that is in the way. The
/// things that genuinely can't be guessed are: what it was, what it cost, who
/// was there, and who paid. Everything else either has an obvious default or
/// can be worked out.
///
/// So: the day and time are now, because that's when you're typing; the
/// category is chosen by Apple Intelligence from the name, because "snacks" is
/// enough to know it's food; everyone is on it until you take someone off; and
/// the split is equal until you say otherwise. Each of those is visible and
/// one tap from being changed — the point is that none of them stop you.
///
/// Only offered while the trip is running. Before it starts, nothing has
/// "just happened", and a booking made in advance is exactly the case the full
/// editor is for.
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss

    let travellers: [Traveller]
    let currencyCode: String
    /// The day this lands on — today, unless the trip's clock disagrees.
    let day: Date
    var onSave: (ItineraryItem) -> Void
    /// Hands what's been typed so far to the full editor.
    var onSwitchToDetailed: (ItineraryItem) -> Void

    @State private var title = ""
    @State private var amount = ""
    @State private var participants: Set<UUID>
    @State private var payerID: UUID?
    @State private var split: SplitMode = .equal
    @FocusState private var titleFocused: Bool

    /// Quick can't collect per-person amounts — that's a table, and a table is
    /// the opposite of this screen.
    private static let splits: [SplitMode] = [.equal, .participants, .organiser, .individual]

    init(
        travellers: [Traveller],
        currencyCode: String,
        day: Date,
        onSave: @escaping (ItineraryItem) -> Void,
        onSwitchToDetailed: @escaping (ItineraryItem) -> Void
    ) {
        self.travellers = travellers
        self.currencyCode = currencyCode
        self.day = day
        self.onSave = onSave
        self.onSwitchToDetailed = onSwitchToDetailed
        _participants = State(initialValue: Set(travellers.map(\.id)))
        // You're the one holding the phone, having just paid for something.
        _payerID = State(initialValue: travellers.first { $0.id == Traveller.you.id }?.id)
    }

    private var canSave: Bool {
        title.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fields
                    who
                    paid
                    sharing
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) { saveBar }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .task {
            // A beat, not `onAppear`. Focusing while the sheet is still
            // animating in gets dropped — the field ends up focused-but-not,
            // with no keyboard and no caret, on a screen whose entire premise
            // is that you can type one line and be gone.
            try? await Task.sleep(for: .milliseconds(360))
            titleFocused = true
        }
    }

    // MARK: - Chrome

    /// The mode switch is the header, not a row inside it. Quick is the
    /// default and the common case; the full editor is one tap away and says
    /// so, rather than being something you have to back out of this to find.
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Add to the trip")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(nowLine)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                    .accessibilityLabel("Close")
            }

            HStack(spacing: 4) {
                modeTab("Quick", isOn: true) {}
                modeTab("Detailed", isOn: false) { onSwitchToDetailed(compose()) }
            }
            .padding(4)
            .panelSurface(corner: 22)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func modeTab(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard !isOn else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(isOn ? AppTheme.ctaLabel : AppTheme.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background { if isOn { Capsule().fill(AppTheme.cta) } }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    /// Says out loud what it's about to record, so "no date field" doesn't read
    /// as "no date".
    private var nowLine: String {
        "Logging for \(DateFormatter.cached("EEE d MMM").string(from: day)), \(DateFormatter.cached("h:mm a").string(from: Date()))"
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 20)

                TextField(
                    "",
                    text: $title,
                    prompt: Text("Beach snacks").foregroundColor(AppTheme.inkTertiary)
                )
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .focused($titleFocused)
                .submitLabel(.done)
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .panelSurface(corner: 18)

            HStack(spacing: 12) {
                Text(Money.symbol(for: currencyCode))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 20)

                TextField(
                    "",
                    text: $amount,
                    prompt: Text("0").foregroundColor(AppTheme.inkTertiary)
                )
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .panelSurface(corner: 18)
        }
    }

    // MARK: - People

    private var who: some View {
        VStack(alignment: .leading, spacing: 9) {
            label("Who's in", trailing: participants.count == travellers.count ? "everyone" : "\(participants.count) of \(travellers.count)")

            faces { traveller in
                let on = participants.contains(traveller.id)

                return Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        if on {
                            // Never down to nobody — an expense on no one isn't
                            // a state the ledger can do anything with.
                            if participants.count > 1 { participants.remove(traveller.id) }
                        } else {
                            participants.insert(traveller.id)
                        }
                    }
                } label: {
                    face(traveller, on: on, mark: "checkmark")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var paid: some View {
        VStack(alignment: .leading, spacing: 9) {
            label("Who paid", trailing: payerID == nil ? "nobody yet" : nil)

            faces { traveller in
                let on = payerID == traveller.id

                return Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        payerID = on ? nil : traveller.id
                    }
                } label: {
                    face(traveller, on: on, mark: "indianrupeesign")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func faces<Row: View>(@ViewBuilder _ row: @escaping (Traveller) -> Row) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(travellers) { traveller in
                    row(traveller)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func face(_ traveller: Traveller, on: Bool, mark: String) -> some View {
        VStack(spacing: 5) {
            MemojiAvatar(traveller: traveller, size: 46)
                .saturation(on ? 1 : 0)
                .opacity(on ? 1 : 0.4)
                .overlay(alignment: .bottomTrailing) {
                    if on {
                        Image(systemName: mark)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(AppTheme.accent, in: .circle)
                            .overlay { Circle().strokeBorder(AppTheme.card, lineWidth: 2) }
                            .transition(.scale.combined(with: .opacity))
                    }
                }

            Text(traveller.id == Traveller.you.id ? "You" : traveller.name)
                .font(.system(size: 11, weight: on ? .semibold : .regular))
                .foregroundStyle(on ? AppTheme.ink : AppTheme.inkTertiary)
                .lineLimit(1)
        }
        .frame(width: 56)
        .contentShape(.rect)
    }

    // MARK: - Sharing

    /// Deliberately the smallest control on the screen. It's the one thing here
    /// that already has a right answer nearly every time, so it states the
    /// answer and gets out of the way rather than presenting five tiles.
    private var sharing: some View {
        HStack(spacing: 10) {
            Text("Cost is")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)

            Menu {
                ForEach(Self.splits) { mode in
                    Button {
                        split = mode
                    } label: {
                        Label(mode.label, systemImage: split == mode ? "checkmark" : mode.symbol)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: split.symbol)
                        .font(.system(size: 11, weight: .bold))
                    Text(split.shortLabel.lowercased())
                        .font(.system(size: 13.5, weight: .semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(AppTheme.accent.opacity(0.12), in: .capsule)
                .contentShape(.capsule)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if let each = shareEach {
                Text("\(Money.format(each, code: currencyCode)) each")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .panelSurface(corner: 18)
        .animation(.easeOut(duration: 0.2), value: split)
    }

    private var shareEach: Double? {
        let cost = Double(amount) ?? 0
        guard cost > 0 else { return nil }

        let heads: Int
        switch split {
        case .equal: heads = travellers.count
        case .participants: heads = max(1, participants.count)
        case .organiser, .individual, .custom: heads = 1
        }
        return cost / Double(heads)
    }

    private func label(_ text: String, trailing: String? = nil) -> some View {
        HStack(spacing: 6) {
            Text(text.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            if let trailing {
                Text("· \(trailing)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary.opacity(0.8))
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 2)
    }

    // MARK: - Save

    /// The booking as currently typed. Shared by the save bar and the handover
    /// to the full editor, so switching modes never loses what's on screen.
    private func compose() -> ItineraryItem {
        let now = Date()
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)

        return ItineraryItem(
            title: title.trimmingCharacters(in: .whitespaces),
            // Category is inferred after the fact — see `commit`. Until then
            // the catch-all, which is what an unclassified thing on a trip is.
            kind: .activity,
            date: day,
            time: .at(parts.hour ?? 12, parts.minute ?? 0, on: day),
            cost: max(0, Double(amount) ?? 0),
            split: split,
            participantIDs: participants,
            paidByID: payerID,
            paymentMethod: payerID == nil ? nil : AppSettings.defaultPaymentMethod
        )
    }

    private var saveBar: some View {
        Button(action: commit) {
            HStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("Add")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func commit() {
        let item = compose()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSave(item)
        dismiss()

        // The classification runs after the booking is already on the timeline.
        // It takes a moment, and nobody standing at a beach shack should watch
        // a spinner to find out that snacks are food — `addItem` upserts, so
        // the second save corrects the row rather than adding another.
        Task { @MainActor in
            let kind = await ActivityIconSuggester.kind(for: item.title)
            let symbol = await ActivityIconSuggester.symbol(for: item.title, kind: kind)

            guard kind != item.kind || symbol != item.suggestedSymbol else { return }

            var classified = item
            classified.kind = kind
            classified.suggestedSymbol = symbol
            onSave(classified)
        }
    }
}
