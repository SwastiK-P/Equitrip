//
//  NoTripsAhead.swift
//  Equitrip
//

import SwiftUI

/// The Itinerary tab with nothing in front of it.
///
/// Two screens share this: an account with no trips at all, and — the common
/// one — an account whose trips have all finished. The second used to be the
/// "Wrapped up" shelf sitting alone at the top of an otherwise blank page,
/// which reads as a list that failed to load rather than as a tab that's up
/// to date.
///
/// The mark is a luggage tag with nothing written on it, hanging and swaying.
/// It's a thing rather than a diagram of one — no dotted routes, no rows
/// standing in for bookings — and it says what the line under it says: the
/// bag isn't going anywhere yet.
///
/// There's no button. The screen already has one, at the top right, and a
/// second copy in the middle of the page would be two front doors to the same
/// room; the pencilled note points at the one that's there, which is also the
/// one people will use every time after this.
struct NoTripsAhead: View {
    /// Whether anything is behind the user. It changes the sentence, not the
    /// mark — "No trips yet" is the wrong thing to tell somebody with six of
    /// them wrapped up.
    var hasFinishedTrips: Bool

    /// The note and the line assemble after the tag, the same entrance the
    /// empty chat thread uses. The tag never stops moving, so without this
    /// the type would cut in over a mark already swinging.
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            StartHereNote()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .rise(appeared, delay: 0.24)

            BlankTag()
                .opacity(appeared ? 1 : 0)
                .animation(.smooth(duration: 0.55), value: appeared)

            Text(hasFinishedTrips ? "Nothing coming up" : "No trips yet")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 16)
                .rise(appeared, delay: 0.1)
        }
        .frame(maxWidth: .infinity)
        .onAppear { appeared = true }
    }
}

// MARK: - The note

/// The pencilled note at the new-trip button.
///
/// Drawn in the same hand as the two notes on Equi's opening screen — the
/// app has one handwriting and one arrow, and this is them. It's aimed by the
/// same arithmetic the header uses to place the button: the tip stops a
/// button's half-width in from the trailing edge, so it keeps pointing at the
/// plus on any width rather than at a spot that happened to be under it on a
/// phone.
private struct StartHereNote: View {
    /// The box the note is drawn in, trailing-aligned against the page's own
    /// content width.
    private static let width: CGFloat = 236
    private static let height: CGFloat = 82

    /// Where the plus is: the header's gutter plus half a button, measured
    /// from the trailing edge.
    private static let target = CGPoint(x: (width - 35) / width, y: 0.05)

    var body: some View {
        ZStack {
            EquiHandArrow(
                from: CGPoint(x: 0.40, y: 0.60),
                to: Self.target,
                control: CGPoint(x: 0.68, y: 0.68),
                head: 8
            )
            .stroke(
                AppTheme.inkSecondary.opacity(0.5),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )

            Text("Start a new trip")
                .font(EquiHand.font(17))
                .foregroundStyle(AppTheme.inkSecondary.opacity(0.78))
                .rotationEffect(.degrees(-7))
                .position(x: Self.width * 0.20, y: Self.height * 0.42)
        }
        .frame(width: Self.width, height: Self.height)
        .accessibilityElement()
        .accessibilityLabel("Start a new trip with the plus button at the top of the screen")
    }
}

private extension View {
    /// One staggered entrance, so the block assembles top-down.
    func rise(_ appeared: Bool, delay: Double) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.smooth(duration: 0.45).delay(delay), value: appeared)
    }
}

// MARK: - The mark

/// A luggage tag on a string, blank, swinging.
///
/// The swing is a pendulum rather than a loop with a rest in it. An empty
/// state is a screen people stop on, and anything that plays, finishes and
/// restarts announces itself every few seconds; a tag that is simply never
/// quite still reads as an object in the room instead. Two sine waves of
/// unrelated periods keep it off a metronome, and a third, very slow one
/// swells the whole thing every quarter of a minute, so every so often it
/// catches a draught and settles back down.
///
/// Driven off the clock rather than by `withAnimation`, the way `QRBurst` is:
/// the angle is one continuous function of time with no states to get stuck
/// between, and it can be read in a line.
private struct BlankTag: View {
    /// A tag swinging in the corner of the eye is exactly what this setting
    /// is for. Reduced, it hangs a little off true and stays there.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start = Date()

    var body: some View {
        Group {
            if reduceMotion {
                tag(swing: .degrees(-3.5))
            } else {
                // 60fps rather than the display link: one rotation of one
                // small subtree, on screen for as long as the tab is open.
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    tag(swing: Tag.swing(at: timeline.date.timeIntervalSince(start)))
                }
            }
        }
        .frame(width: Tag.width, height: Tag.height)
        .accessibilityHidden(true)
    }

    private func tag(swing: Angle) -> some View {
        ZStack(alignment: .topLeading) {
            string
            card
            hook
        }
        .frame(width: Tag.width, height: Tag.height, alignment: .topLeading)
        // Everything turns about the hook, string included — the tag hangs
        // from that point, so rotating the card alone would leave it sliding
        // along a stationary thread.
        .rotationEffect(swing, anchor: Tag.pivot)
    }

    /// Drawn before the card and therefore behind it, which is what puts it
    /// through the punched hole rather than across the face of the tag.
    private var string: some View {
        Path { path in
            path.move(to: Tag.hook)
            path.addLine(to: Tag.eyelet)
        }
        .stroke(AppTheme.inkTertiary.opacity(0.38), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }

    /// The tag itself: the app's own card stock cut to a tag's shoulders, a
    /// punched hole with a ring round it, the aeroplane the app is named
    /// after printed small under the hole — and then the write-on panel,
    /// blank. The blank panel is the whole message, so nothing is allowed to
    /// sit in it.
    private var card: some View {
        TagFace()
            .fill(AppTheme.card, style: FillStyle(eoFill: true))
            .overlay {
                TagFace()
                    .stroke(AppTheme.cardStroke.opacity(0.08), style: StrokeStyle(lineWidth: 1))
            }
            .overlay {
                Circle()
                    .strokeBorder(AppTheme.inkTertiary.opacity(0.28), lineWidth: 1.4)
                    .frame(width: Tag.holeRadius * 2 + 6, height: Tag.holeRadius * 2 + 6)
                    .position(Tag.eyelet)
            }
            .overlay {
                Image(systemName: "airplane")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.accent.opacity(0.8))
                    .rotationEffect(.degrees(-45))
                    .position(Tag.mark)
            }
            .overlay { panel }
            .shadow(color: AppTheme.softShadow(.light), radius: 15, y: 9)
    }

    /// Where a destination would be written, with nothing written on it.
    private var panel: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(AppTheme.inkTertiary.opacity(0.035))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(AppTheme.inkTertiary.opacity(0.11), lineWidth: 1)
            }
            .frame(width: Tag.panel.width, height: Tag.panel.height)
            .position(x: Tag.panel.midX, y: Tag.panel.midY)
    }

    /// What it hangs from. A peg, not a pin — small enough to read as the
    /// point the tag turns about and nothing more.
    private var hook: some View {
        Circle()
            .fill(AppTheme.inkTertiary.opacity(0.45))
            .frame(width: 5, height: 5)
            .position(Tag.hook)
    }
}

// MARK: - Geometry and swing

/// The tag's measurements and the motion of it.
private enum Tag {
    static let width: CGFloat = 156
    static let height: CGFloat = 176

    /// The face, and the local box the silhouette is cut in.
    static let faceWidth: CGFloat = 92
    static let faceHeight: CGFloat = 126
    static let faceTop: CGFloat = 34
    static var faceLeft: CGFloat { (width - faceWidth) / 2 }

    /// A point of the silhouette, in the frame.
    static func face(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: faceLeft + x, y: faceTop + y)
    }

    /// Where it hangs from, and the hole the string runs through.
    static let hook = CGPoint(x: width / 2, y: 8)
    static var eyelet: CGPoint { face(faceWidth / 2, 16) }
    static let holeRadius: CGFloat = 4.5

    static var pivot: UnitPoint { UnitPoint(x: hook.x / width, y: hook.y / height) }

    /// The printed mark, between the hole and the panel.
    static var mark: CGPoint { face(faceWidth / 2, 40) }

    /// The write-on panel: the blank the whole thing is about.
    static var panel: CGRect {
        CGRect(x: faceLeft + 11, y: faceTop + 56, width: faceWidth - 22, height: 54)
    }

    /// The silhouette's corners, top-left round to bottom-left, each with the
    /// radius its corner takes. The shoulders are what make it a luggage tag
    /// rather than another rounded rectangle, and they're cut at a shallower
    /// angle than a price tag's so the hole still has card around it.
    static let outline: [(point: CGPoint, radius: CGFloat)] = [
        (CGPoint(x: 31, y: 0), 6),
        (CGPoint(x: 61, y: 0), 6),
        (CGPoint(x: faceWidth, y: 31), 10),
        (CGPoint(x: faceWidth, y: faceHeight), 16),
        (CGPoint(x: 0, y: faceHeight), 16),
        (CGPoint(x: 0, y: 31), 10)
    ]

    // MARK: Swing

    /// Two swings of unrelated period, swelled by a third that takes a
    /// quarter of a minute to come round.
    ///
    /// The periods are deliberately not multiples of one another: any two
    /// that share a factor re-align every few seconds and the tag starts
    /// repeating a shape the eye can learn, which is the difference between
    /// something hanging in a room and something animating on a screen.
    static func swing(at time: Double) -> Angle {
        let fast = sin(time * 2 * .pi / 3.1)
        let slow = sin(time * 2 * .pi / 5.3 + 0.9)
        let draught = 0.68 + 0.42 * (0.5 + 0.5 * sin(time * 2 * .pi / 17.3))

        return .degrees(draught * (6.4 * fast + 2.1 * slow))
    }
}

/// The face of the tag: the shoulders, the rounded body, and the hole
/// punched out of it.
///
/// One path with two subpaths rather than a card with a hole-coloured disc on
/// top, because the hole has to be a *hole* — the string behind it shows
/// through, and so does whatever the tag is swinging over.
private struct TagFace: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Each corner is drawn as an arc tangent to the two edges meeting at
        // it, which rounds a six-sided outline without working out where the
        // shoulders' bevels start and stop by hand.
        let corners = Tag.outline
        let first = corners[0].point
        let last = corners[corners.count - 1].point
        path.move(to: Tag.face((first.x + last.x) / 2, (first.y + last.y) / 2))

        for index in corners.indices {
            let corner = corners[index]
            let next = corners[(index + 1) % corners.count].point
            path.addArc(
                tangent1End: Tag.face(corner.point.x, corner.point.y),
                tangent2End: Tag.face(next.x, next.y),
                radius: corner.radius
            )
        }
        path.closeSubpath()

        path.addEllipse(
            in: CGRect(
                x: Tag.eyelet.x - Tag.holeRadius,
                y: Tag.eyelet.y - Tag.holeRadius,
                width: Tag.holeRadius * 2,
                height: Tag.holeRadius * 2
            )
        )

        return path
    }
}
