//
//  NewTripFlow.swift
//  Equitrip
//

import SwiftUI

/// Creating a trip, both ways in.
///
/// The two routes converge deliberately: importing a PDF and filling the form
/// by hand both end at the same review screen, because in either case the
/// person needs to check what's about to become the group's shared truth
/// before it goes in. The import route is a head start, not a shortcut past
/// that check.
struct NewTripFlow: View {
    @Environment(\.dismiss) private var dismiss

    var onCreate: (TripDraft) -> Void
    /// Opened straight into joining, e.g. from a scanned link.
    var startOnJoin: Bool = false

    @State private var stage: Stage = .source
    @State private var draft = TripDraft()

    enum Stage: Int, Hashable {
        case source, importing, participants, basics, review, join

        var title: String {
            switch self {
            case .source: "New trip"
            case .importing: "Reading your document"
            case .participants: "Travellers"
            case .basics: "Trip basics"
            case .review: "Check it over"
            case .join: "Join a trip"
            }
        }

        /// Where the back button goes. `source` is the exit.
        var previous: Stage? {
            switch self {
            case .source: nil
            case .importing, .basics, .join: .source
            case .participants: .source
            case .review: .source
            }
        }

        /// How far along the three-step run this is, or nil for the screens
        /// that aren't part of it. The fork and the join flow are separate
        /// errands, not steps toward a trip.
        var step: Int? {
            switch self {
            case .source, .join: nil
            case .importing, .basics: 1
            case .participants: 2
            case .review: 3
            }
        }
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            Group {
                switch stage {
                case .source:
                    TripSourceStage(
                        onImport: { go(.importing) },
                        onManual: {
                            draft = TripDraft()
                            go(.basics)
                        },
                        onJoin: { go(.join) }
                    )

                case .importing:
                    TripImportStage(
                        onExtracted: { extracted in
                            draft = extracted
                            // A document that counted heads without naming them
                            // leaves a question only the person can answer, and
                            // it has to be answered before the costs mean
                            // anything. A document that named everybody, or
                            // never mentioned a number, skips this.
                            go(extracted.needsParticipants ? .participants : .review)
                        },
                        onManualInstead: {
                            draft = TripDraft()
                            go(.basics)
                        }
                    )

                case .participants:
                    TripParticipantsStage(draft: $draft, onContinue: { go(.review) })

                case .basics:
                    TripBasicsStage(draft: $draft, onContinue: { go(.review) })

                case .join:
                    JoinTripFlow()

                case .review:
                    TripReviewStage(
                        draft: $draft,
                        onCreate: {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            onCreate(draft)
                            dismiss()
                        }
                    )
                }
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) {
            if stage != .join { header }
        }
        .onAppear {
            if startOnJoin { stage = .join }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 9) {
            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 12) {
                    CircleGlyphButton(
                        symbol: stage.previous == nil ? "xmark" : "chevron.left",
                        size: 40
                    ) {
                        if let previous = stage.previous {
                            go(previous, backwards: true)
                        } else {
                            dismiss()
                        }
                    }
                    .accessibilityLabel(stage.previous == nil ? "Close" : "Back")

                    Spacer(minLength: 0)

                    Text(stage.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .contentTransition(.opacity)

                    Spacer(minLength: 0)

                    // Balances the back button so the title stays optically centred.
                    Color.clear.frame(width: 40, height: 40)
                }
            }

            if let step = stage.step {
                StepTrack(step: step, of: 3)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func go(_ next: Stage, backwards: Bool = false) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            stage = next
        }
    }
}

// MARK: - Progress

/// Three cells that fill as the flow advances.
///
/// Deliberately not a percentage bar: the steps aren't equal lengths and
/// nobody is estimating time here. What it answers is "how much more of this
/// is there", which a form with no visible end is bad at telling you.
private struct StepTrack: View {
    let step: Int
    let of: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...of, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AppTheme.accent : AppTheme.cardStroke.opacity(0.12))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(step) of \(of)")
    }
}

// MARK: - Source

/// The fork: import a document, build it by hand, or join someone else's.
///
/// It was a list of three rows — a glyph in a gutter, a title, two lines of
/// explanation each. Correct, legible, and completely inert: the first thing
/// anybody sees when they decide to plan a trip was a settings screen. This
/// gives the choice some shape instead. The import route, which is the one
/// worth taking when there's a booking email sitting in your inbox, gets a
/// full-width card with room for an illustration; the other two share a row
/// underneath, which also says something true about their relative weight.
private struct TripSourceStage: View {
    let onImport: () -> Void
    let onManual: () -> Void
    let onJoin: () -> Void

    @State private var appeared = false

    private var availability: IntelligenceAvailability {
        TripExtractor().availability
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headline
                    .staggered(0, appeared)

                importCard
                    .staggered(1, appeared)

                HStack(spacing: 12) {
                    smallCard(
                        symbol: "square.and.pencil",
                        title: "From scratch",
                        detail: "Dates, people, done.",
                        tint: Palette.greenDeep,
                        action: onManual
                    )
                    .staggered(2, appeared)

                    smallCard(
                        symbol: "qrcode.viewfinder",
                        title: "Join a trip",
                        detail: "Scan or type a code.",
                        tint: Palette.violetDeep,
                        action: onJoin
                    )
                    .staggered(3, appeared)
                }

                if !availability.isReady {
                    fallbackNote
                        .staggered(4, appeared)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Where are we")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("going?")
                .font(AppTheme.display(32))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.bottom, 2)
    }

    // MARK: Import

    /// The lead card. The illustration is the point of it: three booking chips
    /// fanned out of a document, which says what the import actually does in
    /// less space than the sentence underneath it needs.
    private var importCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onImport()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                DocumentFan()
                    .frame(height: 132)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Import a document")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Spacer(minLength: 4)

                        if availability.isReady {
                            TagChip(title: "Apple Intelligence", symbol: "sparkles")
                        }
                    }

                    Text("Drop in a booking PDF — flights, stays and activities come out the other side.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                LinearGradient(
                    colors: [AppTheme.accent.opacity(0.16), AppTheme.accent.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(AppTheme.card)
            }
            .clipShape(.rect(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(AppTheme.accent.opacity(0.16))
            }
            .shadow(color: AppTheme.softShadow(.light), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Secondary

    private func smallCard(
        symbol: String,
        title: String,
        detail: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.13), in: .circle)

                Spacer(minLength: 14)

                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 148, alignment: .topLeading)
            .padding(14)
            .background(AppTheme.card, in: .rect(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.05))
            }
            .shadow(color: AppTheme.softShadow(.light), radius: 10, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var fallbackNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.top, 1)

            Text(availability.detail)
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Illustration

/// A page with three bookings coming off it.
///
/// Drawn rather than shipped as an asset so it picks up the app's own palette
/// and stays crisp at any size. The chips drift in on a stagger the first time
/// the screen appears and then hold still — the motion is there to explain the
/// picture once, not to keep performing.
private struct DocumentFan: View {
    @State private var appeared = false

    private struct Chip {
        let symbol: String
        let tint: Color
        let offset: CGSize
        let angle: Double
        let width: CGFloat
    }

    private static let chips: [Chip] = [
        .init(symbol: "airplane", tint: Palette.blue, offset: CGSize(width: 54, height: -30), angle: -8, width: 96),
        .init(symbol: "bed.double.fill", tint: Palette.violet, offset: CGSize(width: 74, height: 6), angle: 4, width: 108),
        .init(symbol: "figure.hiking", tint: Palette.green, offset: CGSize(width: 58, height: 42), angle: -3, width: 92)
    ]

    var body: some View {
        ZStack {
            page
                .offset(x: -62)
                .rotationEffect(.degrees(-5))

            ForEach(Array(Self.chips.enumerated()), id: \.offset) { index, chip in
                bookingChip(chip)
                    .offset(
                        x: appeared ? chip.offset.width : chip.offset.width - 40,
                        y: chip.offset.height
                    )
                    .rotationEffect(.degrees(appeared ? chip.angle : chip.angle - 6))
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.72)
                        .delay(0.12 + Double(index) * 0.09),
                        value: appeared
                    )
            }
        }
        .onAppear { appeared = true }
        .accessibilityHidden(true)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<5, id: \.self) { row in
                Capsule()
                    .fill(AppTheme.inkTertiary.opacity(row == 0 ? 0.35 : 0.16))
                    .frame(width: row == 0 ? 42 : [64, 54, 60, 38][row - 1], height: row == 0 ? 6 : 4)
            }
        }
        .frame(width: 84, height: 106, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.card, in: .rect(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.08))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 8, y: 4)
    }

    private func bookingChip(_ chip: Chip) -> some View {
        HStack(spacing: 7) {
            Image(systemName: chip.symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(chip.tint, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Capsule().fill(AppTheme.inkTertiary.opacity(0.32)).frame(width: 40, height: 4)
                Capsule().fill(AppTheme.inkTertiary.opacity(0.18)).frame(width: 26, height: 4)
            }

            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: chip.width)
        .background(AppTheme.card, in: .rect(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.06))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 7, y: 3)
    }
}
