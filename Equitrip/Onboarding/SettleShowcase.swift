//
//  SettleShowcase.swift
//  Equitrip
//

import SwiftUI

/// The ledger problem, then the ledger solved.
///
/// Built to sit alongside `OnboardingView` as a second page, and standalone
/// for now — nothing in the app presents it yet, so the previews at the foot
/// of this file are how it's looked at.
///
/// It argues the arithmetic, which is the half of Equitrip nobody believes
/// until they watch it happen — so it doesn't describe it.
/// A trip's worth of receipts drops onto the screen one at a time, the way
/// they arrive in life: no order, each one somebody else's money, and no way
/// to tell from looking at them who is out of pocket. A beat later the pile
/// collapses into the three payments that clear it.
///
/// It plays itself. There was an Organise button here, and it was the wrong
/// idea twice over: it asked for work before the screen had earned any, and
/// it sat six points above the real call to action, so the page offered two
/// buttons and no clue which one mattered. The claim is that the app does
/// this without being asked, and the honest way to make that claim is to do
/// it without being asked. It replays every time the page comes back, so it's
/// never a still picture of a conclusion somebody missed.
///
/// The scatter is deliberate, and deliberately the opposite of
/// `OnboardingHero`'s grid-aligned deck. There the composition *is* the
/// product, so it's tidy. Here the mess is the argument: the card only earns
/// its tidiness by following something genuinely untidy.
struct SettleShowcase: View {
    /// Whether this is the page on screen. The deal waits for it — the
    /// receipts landing one by one is the whole opening, and playing it to an
    /// empty room means arriving to a pile that was always there.
    ///
    /// Defaults to true so the screen works on its own; a pager hosting it
    /// alongside other pages passes its own selection through instead.
    var visible: Bool = true
    var compact: Bool = false

    /// Bumped once when the page first arrives, and again on every replay.
    /// Driving the sequence off a counter rather than a `Bool` is what makes
    /// it replayable: `.task(id:)` restarts on any change and cancels the run
    /// in flight, so a second tap can't leave two sequences dealing into each
    /// other.
    @State private var run = 0

    /// How many receipts have landed. Everything about a receipt's
    /// appearance falls out of this and `organised`, so there is no per-chip
    /// state to get out of step with the sequence.
    @State private var arrived = 0
    @State private var organised = false

    private let demo = SettleDemo.goa

    var body: some View {
        VStack(spacing: 0) {
            headline
                .padding(.top, compact ? 28 : 48)

            Spacer(minLength: compact ? 2 : 4)

            stage
                .frame(maxHeight: .infinity)

            Spacer(minLength: compact ? 4 : 12)
        }
        .onAppear {
            guard visible, run == 0 else { return }
            run = 1
        }
        // Every arrival, not just the first. Coming back to a settled card is
        // arriving at the punchline with the joke already told — the sequence
        // is the entire content of the screen, so returning has to start it
        // over.
        .onChange(of: visible) { _, now in
            guard now else { return }
            run += 1
        }
        .task(id: run) {
            guard run > 0 else { return }
            await play()
        }
        // VoiceOver only. A tap-to-replay was here and had to go: the page
        // lives inside a paging `TabView`, whose pan gesture claims the touch
        // long before a tap on the content resolves, so the gesture did
        // nothing most of the time and turned the page the rest of it. An
        // affordance that unreliable is worse than none — arriving on the
        // page is the replay.
        .accessibilityAction(named: "Play it again") { run += 1 }
    }

    // MARK: - The sequence

    /// Receipts landing one at a time, a beat to take in the mess, then the
    /// collapse — the whole argument, unattended, in a little over two
    /// seconds.
    ///
    /// The haptics go out as one Core Haptics pattern up front rather than a
    /// tap per iteration: this loop's `Task.sleep` is accurate to a few
    /// milliseconds each time and the error accumulates over nine of them, so
    /// taps fired from inside it slide off the frames they belong to. The
    /// pattern is scheduled against the audio clock and doesn't drift, which
    /// is what keeps the ticks under the receipts rather than behind them.
    private func play() async {
        // Clears whatever the last run left. Animated, because on a "Scatter
        // again" the card is still on screen and has to get out of the way
        // before the first receipt lands on top of it.
        withAnimation(.easeOut(duration: 0.2)) {
            organised = false
            arrived = 0
        }

        try? await Task.sleep(for: .seconds(0.2))

        SettleHaptics.deal(count: demo.expenses.count, step: SettleTiming.dealStep)

        for _ in demo.expenses.indices {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.66)) { arrived += 1 }
            try? await Task.sleep(for: .seconds(SettleTiming.dealStep))
        }

        // Long enough to read two or three of them and register that there is
        // no answer in there anywhere. Collapsing straight away makes the pile
        // look like a loading state rather than the problem.
        try? await Task.sleep(for: .seconds(SettleTiming.settlePause))

        // A replay tap cancels this task partway through the pause; without
        // the check the cancelled run would still settle, on top of the deal
        // the new one has already started.
        guard !Task.isCancelled else { return }

        SettleHaptics.gather(payments: demo.transfers.count)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) { organised = true }
    }

    // MARK: - Headline

    /// Both halves stay in the tree and cross-fade, so the block keeps one
    /// height whichever is showing. Swapping a single `Text` re-measures it,
    /// and a headline that grows a line on tap shoves the whole stage down at
    /// the exact moment the animation wants the user looking at it.
    ///
    /// No `lineLimit`: the copy is written to two lines apiece, but a capped
    /// line count is a truncated headline the first time a translation or a
    /// larger type size disagrees. Letting it size itself costs nothing here —
    /// the stage below is the flexible part.
    private var headline: some View {
        ZStack {
            copy(
                title: "\(spelled(demo.expenses.count)) receipts.\nNobody's counting.",
                subtitle: "This is what a group trip's money actually looks like."
            )
            .opacity(organised ? 0 : 1)
            .offset(y: organised ? -8 : 0)

            copy(
                title: "\(spelled(demo.transfers.count)) payments.\nEverybody square.",
                subtitle: "Every debt nets off against the others until only these are left."
            )
            .opacity(organised ? 1 : 0)
            .offset(y: organised ? 0 : 8)
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.9)
                .delay(organised ? SettleTiming.rowDelay : 0.04),
            value: organised
        )
        .padding(.horizontal, 22)
    }

    /// "Six", "Three" — a headline counts in words, and these two count the
    /// actual arrays. They were written out by hand first and the receipts
    /// one was already lying within the hour of the list being shortened,
    /// which is exactly the drift `SettleDemo` derives everything else to
    /// avoid.
    private func spelled(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        let word = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    private func copy(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: compact ? 27 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .multilineTextAlignment(.center)
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Stage

    /// The receipts and the card share one coordinate space, because the
    /// receipts have to converge on where the card actually is rather than on
    /// a number that happens to match it today.
    private var stage: some View {
        GeometryReader { geo in
            // Just above the centre. Dead centre left a band of empty canvas
            // between the card and the subtitle that read as a missing
            // element rather than as breathing room, because the pile it
            // replaces starts right under the headline. Nudged up, it picks up
            // where the receipts were; the card's own height does the rest of
            // the work, and what it doesn't use collects at the bottom where
            // the page is running out anyway.
            let focus = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.45)

            ZStack {
                GatherBloom(trigger: organised)
                    .position(focus)

                ForEach(Array(demo.expenses.enumerated()), id: \.element.id) { index, expense in
                    let landed = index < arrived

                    ExpenseChip(expense: expense, currency: demo.currency)
                        .opacity(landed && !organised ? 1 : 0)
                        // Held until the sweep is nearly over, so a receipt
                        // reads as being filed into the card rather than
                        // dimming out on the way there. Scoped to the opacity
                        // alone, and only to `organised` — the deal's own
                        // `withAnimation` still owns the pop-in.
                        .animation(
                            .easeIn(duration: 0.18).delay(organised ? 0.2 : 0),
                            value: organised
                        )
                        .scaleEffect(organised ? 0.5 : (landed ? 1 : 0.72))
                        .position(organised ? focus : spot(expense, in: geo.size))
                }

                SettlementCard(demo: demo, revealed: organised, compact: compact)
                    .frame(width: max(0, geo.size.width - 40))
                    .fitting(geo.size.height)
                    .position(focus)
                    // Nothing in it is interactive, and it covers the middle
                    // of the stage — left hittable it would eat the replay tap
                    // over the largest part of the page.
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(minHeight: 230)
    }

    private func spot(_ expense: SettleDemo.Expense, in size: CGSize) -> CGPoint {
        CGPoint(x: expense.spot.x * size.width, y: expense.spot.y * size.height)
    }
}

// MARK: - Timing

/// Shared by the animation and the haptics, so tuning one can't leave the
/// other landing on a frame that no longer exists.
enum SettleTiming {
    /// The gap between two receipts landing. Slow enough to watch each one
    /// arrive and read what it is — they were quick enough at first that the
    /// pile looked like it faded in all at once — and still short enough that
    /// the whole trip is on the table in under two seconds.
    static let dealStep = 0.16
    /// How long the pile sits there being a mess before it settles itself.
    static let settlePause = 1.1
    /// When the card blooms — late enough that the last receipts are already
    /// dissolving into it, early enough that it isn't a separate event.
    static let cardDelay = 0.3
    /// When the first payment row arrives, and the gap between them.
    static let rowDelay = 0.44
    static let rowStep = 0.075
}

// MARK: - Receipt

/// One expense as it looks in the pile: what it was, who fronted it, what it
/// cost. Small enough that half a dozen can overlap without hiding each
/// other, which is the whole point of the composition.
private struct ExpenseChip: View {
    let expense: SettleDemo.Expense
    let currency: String

    var body: some View {
        HStack(spacing: 8) {
            IconTile(symbol: expense.kind.symbol, tint: expense.kind.tint, size: 24, corner: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(expense.title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                HStack(spacing: 3.5) {
                    TravellerAvatar(traveller: expense.payer, size: 12)
                    Text("\(expense.payer.name) paid")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }

            Text(Money.format(expense.amount, code: currency))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .lineLimit(1)
        .fixedSize()
        .padding(.leading, 8)
        .padding(.trailing, 11)
        .padding(.vertical, 7)
        .cardSurface(corner: 14, shadow: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(expense.title), \(Money.format(expense.amount, code: currency)), paid by \(expense.payer.name)"
        )
    }
}

// MARK: - Settlement card

/// What the pile turns into: the trip's total, and the shortest list of
/// payments that leaves nobody owing anybody.
private struct SettlementCard: View {
    let demo: SettleDemo
    let revealed: Bool
    let compact: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
                .revealed(revealed, at: 0)

            Hairline()

            paidStrip
                .revealed(revealed, at: 1)

            Hairline()

            VStack(spacing: compact ? 9 : 16) {
                ForEach(Array(demo.transfers.enumerated()), id: \.element.id) { index, transfer in
                    row(transfer)
                        .revealed(revealed, at: index + 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, compact ? 12 : 19)

            Hairline()

            footer
                .revealed(revealed, at: demo.transfers.count + 2)
        }
        .cardSurface(corner: 26, shadow: 24)
        .scaleEffect(revealed ? 1 : 0.88)
        .opacity(revealed ? 1 : 0)
        .blur(radius: revealed ? 0 : 5)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8)
                .delay(revealed ? SettleTiming.cardDelay : 0),
            value: revealed
        )
        .accessibilityElement(children: .contain)
        .accessibilityHidden(!revealed)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SETTLE UP")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)

                Text(Money.format(demo.total, code: demo.currency))
                    .font(.system(size: compact ? 23 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(demo.expenses.count.pluralised("expense")) · \(demo.people.count) people")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 7) {
                Text(demo.name)
                    .font(AppTheme.display(14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                AvatarStack(travellers: demo.people, size: 24, max: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, compact ? 12 : 17)
    }

    // MARK: Who paid

    /// What each person actually laid out, tallest bar first.
    ///
    /// The payments below are meaningless without it: three arrows between
    /// five strangers is a conclusion with its reasoning cut off. This is the
    /// reasoning — one person fronted the villa, somebody else bought a round
    /// of lunch, and the row of unequal bars is the entire reason anybody owes
    /// anybody. It also answers the question the scattered receipts were
    /// asking, which is who has been carrying this trip.
    private var paidStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHO PAID")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            HStack(spacing: 0) {
                ForEach(demo.paid, id: \.person.id) { entry in
                    VStack(spacing: 7) {
                        TravellerAvatar(traveller: entry.person, size: compact ? 24 : 32)

                        // Scaled against the biggest payer rather than the
                        // trip total: five bars at a fifth of the width each
                        // would be five stubs, and the comparison worth
                        // drawing is between the people, not with the total.
                        Capsule()
                            .fill(AppTheme.accent.opacity(0.16))
                            .frame(width: 38, height: 5)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(AppTheme.accent)
                                    .frame(width: 38 * share(entry.amount), height: 5)
                            }

                        Text(Money.format(entry.amount, code: demo.currency))
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, compact ? 11 : 16)
        .accessibilityElement(children: .combine)
    }

    private func share(_ amount: Double) -> CGFloat {
        guard let top = demo.paid.first?.amount, top > 0 else { return 0 }
        return CGFloat(amount / top)
    }

    // MARK: Rows

    /// One payment. The two faces and the arrow between them are the sentence;
    /// the amount is the only part anyone reads twice.
    private func row(_ transfer: SettleDemo.Transfer) -> some View {
        HStack(spacing: 8) {
            TravellerAvatar(traveller: transfer.from, size: compact ? 22 : 26)

            Text(transfer.from.name)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Image(systemName: "arrow.right")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.horizontal, 1)

            TravellerAvatar(traveller: transfer.to, size: compact ? 22 : 26)

            Text(transfer.to.name)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 6)

            Text(Money.format(transfer.amount, code: demo.currency))
                .font(.system(size: 15.5, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(transfer.from.name) pays \(transfer.to.name) \(Money.format(transfer.amount, code: demo.currency))"
        )
    }

    // MARK: Footer

    /// The claim the whole screen exists to make, and it's arithmetic rather
    /// than a slogan: every expense leaves everyone who didn't pay owing the
    /// person who did, and that is the number being collapsed.
    private var footer: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.positive)

            Text("\(demo.grossDebts) IOUs netted into \(demo.transfers.count.pluralised("payment"))")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .padding(.horizontal, 16)
        .padding(.vertical, compact ? 10 : 14)
    }
}

private extension View {
    /// The card's blocks arriving one after another, keyed off the same flag
    /// as the card itself so there's no second piece of state to get out of
    /// step with it.
    func revealed(_ on: Bool, at index: Int) -> some View {
        opacity(on ? 1 : 0)
            .offset(y: on ? 0 : 9)
            .animation(
                .spring(response: 0.42, dampingFraction: 0.85)
                    .delay(on ? SettleTiming.rowDelay + Double(index) * SettleTiming.rowStep : 0),
                value: on
            )
    }
}

// MARK: - Fitting

private extension View {
    func fitting(_ limit: CGFloat) -> some View {
        modifier(FitHeight(limit: limit))
    }
}

/// Shrinks a view until it fits the height it's been given.
///
/// The card is built out of fixed point sizes, and the compact branch that
/// keeps it inside a small screen is a set of numbers somebody tuned by hand
/// against the phones they happened to have. That holds right up until a
/// device with a different aspect, a larger Dynamic Type setting or a
/// translation with longer names pushes one row onto two lines — and the
/// failure mode is the bottom of the settlement card cut off, on the one
/// screen whose entire job is to look resolved.
///
/// So the numbers stay as the design, and this is the guarantee. The height
/// is measured before the scale is applied — `scaleEffect` doesn't change
/// layout, so the reading is always of the natural size and can't feed back
/// into itself.
private struct FitHeight: ViewModifier {
    let limit: CGFloat

    @State private var natural: CGFloat = 0

    private var scale: CGFloat {
        guard natural > 0, limit > 0 else { return 1 }
        return min(1, limit / natural)
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { natural = $0 }
            .scaleEffect(scale)
    }
}

// MARK: - Bloom

/// The ring thrown off as the pile lands, so the collapse has a moment of
/// impact instead of simply stopping.
///
/// A keyframe track rather than a spring, because the shape of it matters:
/// nothing at all while the receipts are still travelling, a hard flash on
/// the frame they arrive, then a slow bleed outward. A spring can't hold
/// still for the first quarter-second.
private struct GatherBloom: View {
    var trigger: Bool

    private struct Frame {
        var scale: CGFloat = 0.3
        var glow: Double = 0
        var width: CGFloat = 9
    }

    var body: some View {
        KeyframeAnimator(initialValue: Frame(), trigger: trigger) { frame in
            Circle()
                .strokeBorder(AppTheme.accent, lineWidth: frame.width)
                .frame(width: 190, height: 190)
                .scaleEffect(frame.scale)
                // Killed outright on the way back out — the receipts are
                // being dealt again there, and a ring expanding through them
                // reads as a second, unrelated event.
                .opacity(trigger ? frame.glow : 0)
                .blur(radius: 4)
                .allowsHitTesting(false)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                LinearKeyframe(0.3, duration: SettleTiming.cardDelay)
                CubicKeyframe(1.5, duration: 0.65)
            }
            KeyframeTrack(\.glow) {
                LinearKeyframe(0, duration: SettleTiming.cardDelay)
                LinearKeyframe(0.45, duration: 0.07)
                CubicKeyframe(0, duration: 0.58)
            }
            KeyframeTrack(\.width) {
                LinearKeyframe(9, duration: SettleTiming.cardDelay + 0.07)
                CubicKeyframe(1, duration: 0.58)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Light") {
    ZStack {
        CanvasBackground()
        SettleShowcase(visible: true)
    }
}

#Preview("Dark") {
    ZStack {
        CanvasBackground()
        SettleShowcase(visible: true)
    }
    .preferredColorScheme(.dark)
}
