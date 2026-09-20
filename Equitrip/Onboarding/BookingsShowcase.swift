//
//  BookingsShowcase.swift
//  Equitrip
//

import SwiftUI
import CoreText

/// Onboarding's second page: booking PDFs read into the itinerary on device.
///
/// Self-contained on purpose — it's on trial. Removing it is deleting this
/// file and the `.bookings` case in `OnboardingView.Page`; nothing else
/// references it.
///
/// The composition is a phone showing the real itinerary screen, fading out
/// at the bottom, with the bookings the PDF produced floating over it wider
/// than the phone — the product in the background, the feature in front.
/// Like `SettleShowcase` it plays itself whenever the page becomes visible,
/// because the paging `TabView` swallows taps.
struct BookingsShowcase<Dots: View>: View {
    var visible: Bool = true
    var compact: Bool = false
    /// The pager's page indicator, placed between the stage and the headline.
    @ViewBuilder var dots: Dots

    @State private var run = 0
    @State private var phase = BookingsPhase.idle

    var body: some View {
        VStack(spacing: 0) {
            stage
                .frame(maxHeight: .infinity)
                .padding(.bottom, compact ? 14 : 22)

            dots

            headline
                .padding(.top, compact ? 14 : 20)
        }
        .onAppear {
            guard visible, run == 0 else { return }
            run = 1
        }
        .onChange(of: visible) { _, now in
            if now { run += 1 }
        }
        .task(id: run) {
            guard run > 0 else { return }
            await play()
        }
        .accessibilityAction(named: "Play it again") { run += 1 }
    }

    private func play() async {
        withAnimation(.easeOut(duration: 0.15)) { phase = .idle }
        let steps: [(BookingsPhase, Double)] = [(.phone, 0.15), (.first, 0.6), (.second, 0.28)]
        for (next, wait) in steps {
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { phase = next }
            if next == .first || next == .second {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }

    // MARK: - Stage

    private var stage: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            // As wide as the page allows while the cards still overhang it.
            // The frame runs off the bottom of the stage and fades there.
            let phoneWidth = min(width * 0.82, 350)
            let phoneTop = height * 0.04
            let cardHeight: CGFloat = compact ? 54 : 60
            let cardGap: CGFloat = 8
            // Over the empty lower half of the screenshot, below its booking,
            // but never pushed past the stage onto the page dots.
            let cardsTop = min(
                phoneTop + phoneWidth * PhoneMockup.aspect * 0.56,
                height - cardHeight * 2 - cardGap - 10
            )

            ZStack(alignment: .top) {
                PhoneMockup()
                    .frame(width: phoneWidth, height: phoneWidth * PhoneMockup.aspect)
                    .offset(y: phoneTop + (phase >= .phone ? 0 : 30))
                    .opacity(phase >= .phone ? 1 : 0)
                    .frame(width: width, height: height, alignment: .top)
                    .clipped()
                    // Fades into the canvas instead of ending on a hard edge,
                    // so the floating cards read as lifted out of it.
                    .mask {
                        LinearGradient(
                            stops: [.init(color: .black, location: 0.6), .init(color: .clear, location: 1)],
                            startPoint: .top, endPoint: .bottom
                        )
                    }

                FloatingBooking(booking: .flight, compact: compact)
                    .frame(height: cardHeight)
                    .padding(.horizontal, 26)
                    .offset(y: cardsTop)
                    .opacity(phase >= .first ? 1 : 0)
                    .offset(x: phase >= .first ? 0 : -width * 0.35)
                    .scaleEffect(phase >= .first ? 1 : 0.9)

                FloatingBooking(booking: .stay, compact: compact)
                    .frame(height: cardHeight)
                    .padding(.horizontal, 26)
                    .offset(y: cardsTop + cardHeight + cardGap)
                    .opacity(phase >= .second ? 1 : 0)
                    .offset(x: phase >= .second ? 0 : width * 0.35)
                    .scaleEffect(phase >= .second ? 1 : 0.9)
            }
            .frame(width: width, height: height, alignment: .top)
        }
        .frame(minHeight: compact ? 300 : 340)
    }

    // MARK: - Headline

    /// A handwritten line over a heavy one, after the reference layout. The
    /// script line writes itself in left to right and the bold line lands a
    /// beat later, replaying with the rest of the page on every visit.
    private var headline: some View {
        let shown = phase >= .phone

        return VStack(spacing: compact ? 8 : 12) {
            VStack(spacing: compact ? -2 : 0) {
                Text("Drop a ticket")
                    .font(BrushScript.font(size: compact ? 30 : 34))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 6)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(maxWidth: shown ? .infinity : 0)
                            .animation(.easeInOut(duration: 0.9).delay(0.1), value: shown)
                    }

                Text("Get the Plan")
                    .font(.system(size: compact ? 38 : 44, weight: .semibold))
                    .tracking(-0.8)
                    .foregroundStyle(AppTheme.ink)
                    .scaleEffect(shown ? 1 : 0.85)
                    .opacity(shown ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.55), value: shown)
            }

            Text("Add a ticket or hotel PDF — read on your iPhone, never uploaded.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.inkSecondary)
                .lineSpacing(2)
                .padding(.horizontal, 14)
                .opacity(shown ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.8), value: shown)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 20)
    }
}

/// Kaushan Script (SIL OFL, licence in `docs/onboarding/`), shipped as a data
/// asset and built straight into a `CTFont` — no registration, so no
/// Info.plist font entry, and nothing loose in the synchronized target folder.
/// Falls back to the system italic if it won't load.
private enum BrushScript {
    static let descriptor: CTFontDescriptor? = {
        guard let data = NSDataAsset(name: "KaushanScript")?.data as CFData?,
              let descriptors = CTFontManagerCreateFontDescriptorsFromData(data) as? [CTFontDescriptor]
        else { return nil }
        return descriptors.first
    }()

    static func font(size: CGFloat) -> Font {
        guard let descriptor else { return .system(size: size, weight: .bold).italic() }
        return Font(CTFontCreateWithFontDescriptor(descriptor, size, nil))
    }
}

/// Where the sequence has got to. Each step includes every one before it, so
/// views compare with `>=`.
private enum BookingsPhase: Int, Comparable {
    case idle, phone, first, second
    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}

// MARK: - Phone

/// The real itinerary screen in an iPhone bezel, baked into one image
/// (`OnboardingPhone`) by `scripts/onboarding-phone.py` so the screenshot fits
/// the screen exactly. Sources live in `docs/onboarding/`.
private struct PhoneMockup: View {
    static let aspect: CGFloat = 2656 / 1294

    var body: some View {
        Image("OnboardingPhone")
            .resizable()
            .accessibilityHidden(true)
    }
}

// MARK: - Floating booking

/// A booking the import produced, lifted out of the phone. The time and
/// flight number appear verbatim in the demo PDF — the pipeline copies them,
/// it never writes them.
private struct FloatingBooking: View {
    let booking: DemoBooking
    let compact: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: booking.kind.symbol)
                .font(.system(size: compact ? 13 : 14, weight: .semibold))
                .foregroundStyle(booking.kind.tint)
                .frame(width: compact ? 32 : 36, height: compact ? 32 : 36)
                .background(booking.kind.tint.opacity(0.12), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(booking.title)
                    .font(.system(size: compact ? 13 : 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                    Text(booking.detail)
                }
                .font(.system(size: compact ? 10 : 10.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            }
            .lineLimit(1)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 1) {
                Text(booking.time)
                    .font(.system(size: compact ? 14 : 15.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(booking.day)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
        .padding(.leading, 11)
        .padding(.trailing, 16)
        .frame(maxHeight: .infinity)
        // Liquid glass, so the screenshot shows through the cards the way
        // system chrome floats over content.
        .glassEffect(.regular, in: .rect(cornerRadius: compact ? 27 : 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(booking.title), \(booking.day) at \(booking.time), added from a PDF")
    }
}

private struct DemoBooking {
    let kind: ItineraryKind
    let title: String
    let detail: String
    let time: String
    let day: String

    // The trip in the screenshot behind them: Jharkhand, from Wed 16 Sep.
    static let flight = DemoBooking(
        kind: .flight, title: "IndiGo 6E 5314", detail: "BOM → IXR · e-ticket.pdf", time: "07:40", day: "WED 16"
    )
    static let stay = DemoBooking(
        kind: .stay, title: "Radisson Blu Ranchi", detail: "Check-in · booking.pdf", time: "14:00", day: "WED 16"
    )
}

#Preview {
    ZStack {
        CanvasBackground()
        BookingsShowcase { EmptyView() }
    }
}
