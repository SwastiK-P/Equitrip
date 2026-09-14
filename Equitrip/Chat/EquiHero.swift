//
//  EquiHero.swift
//  Equitrip
//

import SwiftUI
import UIKit

// MARK: - Handwriting

/// The one handwritten face in the app, used only for the two margin notes on
/// Equi's opening screen.
///
/// Resolved once against what the device actually ships rather than hardcoded:
/// `Font.custom` silently falls back to the system face when a name is
/// missing, and a margin note that quietly renders in San Francisco reads as a
/// bug rather than as a note. Asking `UIFont` first means the fallback is a
/// deliberate one — an italic serif, which is at least still *handwriting-ish*
/// — instead of the annotation flattening into the rest of the interface.
enum EquiHand {
    private static let resolved: String? = {
        ["BradleyHandITCTT-Bold", "Noteworthy-Bold", "MarkerFelt-Thin", "SnellRoundhand-Bold"]
            .first { UIFont(name: $0, size: 12) != nil }
    }()

    /// Deliberately `fixedSize`: these sit at hand-placed coordinates against
    /// an illustration, and letting them grow with Dynamic Type would walk
    /// them off their arrows. The scene is decorative and hidden from
    /// VoiceOver, with the same meaning carried in plain text above it.
    static func font(_ size: CGFloat) -> Font {
        guard let resolved else {
            return .system(size: size, weight: .semibold, design: .serif).italic()
        }
        return .custom(resolved, fixedSize: size)
    }
}

// MARK: - Arrow

/// The little curved arrow that connects a margin note to the scene.
///
/// Points are given in the unit square so a caller places the whole gesture in
/// the same coordinate space it places the note — the arrow and its label stay
/// together at any width, which is the entire job.
private struct EquiHandArrow: Shape {
    var from: CGPoint
    var to: CGPoint
    /// The quadratic control point. Pulling it off the straight line between
    /// the ends is what gives the stroke its drawn-by-hand bow.
    var control: CGPoint
    var head: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        func point(_ unit: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + unit.x * rect.width, y: rect.minY + unit.y * rect.height)
        }

        let start = point(from)
        let end = point(to)
        let bend = point(control)

        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: bend)

        // A quadratic's tangent at its end is simply end − control, so the
        // head sits on the curve's real direction rather than on the chord.
        let heading = atan2(end.y - bend.y, end.x - bend.x)
        for spread in [CGFloat.pi * 0.83, -CGFloat.pi * 0.83] {
            let angle = heading + spread
            path.move(to: end)
            path.addLine(to: CGPoint(x: end.x + cos(angle) * head, y: end.y + sin(angle) * head))
        }

        return path
    }
}

// MARK: - Speech bubble

/// A rounded bubble with a tail on its lower-left corner — Equi speaking into
/// the scene.
///
/// Drawn as one continuous outline, with the tail cut into the bottom edge
/// rather than added as a second subpath beside it. The first version did the
/// obvious thing — a rounded rect, then a triangle — and it read as two shapes
/// that happened to touch, for two separate reasons: the stroke ran along the
/// body's bottom edge *through* the tail, drawing a line across the join, and
/// the two subpaths wound opposite ways, so the overlap fell out of the fill
/// under the non-zero rule and left the tail looking hollow. A single path has
/// neither problem, because there is no join to draw and no overlap to cancel.
private struct EquiBubbleShape: Shape {
    var corner: CGFloat = 15
    var tail = CGSize(width: 13, height: 9)

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x, y: rect.minY + y)
        }

        let width = rect.width
        let base = rect.height - tail.height
        let radius = min(corner, min(width, base) / 2)
        // Where the tail meets the body, kept clear of the bottom-left corner.
        let root = min(radius + 4, width - radius - tail.width)

        var path = Path()
        path.move(to: point(radius, 0))
        path.addArc(tangent1End: point(width, 0), tangent2End: point(width, radius), radius: radius)
        path.addArc(tangent1End: point(width, base), tangent2End: point(width - radius, base), radius: radius)

        // Along the bottom edge, down into the tail and back up, still on the
        // same subpath.
        path.addLine(to: point(root + tail.width, base))
        path.addLine(to: point(root - tail.width * 0.35, rect.height))
        path.addLine(to: point(root, base))

        path.addArc(tangent1End: point(0, base), tangent2End: point(0, base - radius), radius: radius)
        path.addArc(tangent1End: point(0, 0), tangent2End: point(radius, 0), radius: radius)
        path.closeSubpath()

        return path
    }
}

/// The three short strokes above the bubble's shoulder — the comic-book mark
/// for "and it just spoke".
private struct EquiSparkBurst: View {
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(AppTheme.accent.opacity(0.55))
                    .frame(width: 2, height: index == 1 ? 11 : 8)
                    .offset(y: index == 1 ? -1 : 0)
                    .rotationEffect(.degrees(Double(index - 1) * 34))
                    .offset(x: Double(index - 1) * 7)
            }
        }
        .frame(width: 26, height: 14)
    }
}

// MARK: - Scene// MARK: - Scene

/// Equi's opening illustration: the valley with Equi as the sun over it, a
/// note pencilled in the margin, and one line of Equi's own.
///
/// The landscape is pinned to the bottom of a box taller than itself, so the
/// notes above it fall first on the artwork's own pale sky and then on the app
/// canvas with no visible seam between the two — which is also why the image
/// is masked out at the top rather than cropped. Everything is placed in unit
/// coordinates against that box rather than in points, so a note, its arrow
/// and the ridge it points at hold their relationship from the narrowest phone
/// to the widest.
struct EquiHeroScene: View {
    var appeared: Bool

    @Environment(\.colorScheme) private var scheme

    /// Tall enough to carry the notes above the horizon; the artwork itself
    /// claims a little over three quarters of it.
    private static let height: CGFloat = 240

    /// The artwork's own proportions. Wrong by even a little and every
    /// coordinate below drifts, because they are all measured against where
    /// the painted sun lands — so it is read off the asset, not eyeballed.
    private static let aspect: CGFloat = 2.41

    /// How far past the screen the artwork is drawn before being clipped back
    /// to it. At its own aspect the valley is a stripe — pushing it out a
    /// tenth and cropping the margins buys real height for the ridges, which
    /// is the half of the picture anyone actually looks at. Kept small on
    /// purpose: past about this the trees on the left bank go over the edge.
    private static let overscan: CGFloat = 1.12

    /// Where Equi is, in this box's unit space. The margin note's arrow is
    /// aimed here.
    ///
    /// Equi is no longer a view — the face is painted into the artwork as the
    /// sun — so nothing here draws it and nothing can ask it where it went.
    /// These numbers are the disc measured off the asset (centre 48.9% × 56.6%
    /// of the image, radius 173px of 1947) pushed through the same overscan
    /// and bottom-pinning the image gets, which is what keeps the notes and
    /// their arrows aimed at a face this file never sees.
    ///
    /// If the artwork is ever replaced, re-measure and update these three.
    private static let sun = CGPoint(x: 0.488, y: 0.663)
    /// The disc's radius as a fraction of the box's *width*, since that is what
    /// the artwork scales with.
    private static let sunRadius: CGFloat = 0.0996

    /// A point `clearance` beyond the sun's rim, at `degrees` around it (0 is
    /// due right, growing clockwise as screen coordinates do).
    ///
    /// The rim is a circle in points but an ellipse in the box's unit space,
    /// so the arithmetic is done in points and converted back at the end.
    /// Hand-written unit coordinates for the arrow tips looked right on one
    /// phone and drifted off the disc on every other one.
    private static func offSun(_ degrees: Double, clearance: CGFloat, in size: CGSize) -> CGPoint {
        let radians = degrees * .pi / 180
        let reach = size.width * sunRadius + clearance
        return CGPoint(
            x: sun.x + CGFloat(cos(radians)) * reach / size.width,
            y: sun.y + CGFloat(sin(radians)) * reach / size.height
        )
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack(alignment: .bottom) {
                landscape(width: size.width)

                bubble(size: size)
                    .equiStagger(1, appeared: appeared)

                note("Plan\nSmarter", size: size, at: CGPoint(x: 0.150, y: 0.235), tilt: -11)
                    .equiStagger(2, appeared: appeared)

                // The arrow stops a little short of the rim rather than on
                // it: an arrow that lands inside what it indicates reads as
                // touching, not as pointing.
                arrow(
                    size: size,
                    from: CGPoint(x: 0.110, y: 0.365),
                    to: Self.offSun(207, clearance: 14, in: size),
                    control: CGPoint(x: 0.125, y: 0.570)
                )
                .equiStagger(3, appeared: appeared)

            }
        }
        .frame(height: Self.height)
        .accessibilityHidden(true)
    }

    /// The artwork, drawn slightly wider than the screen and cropped back to
    /// it, then faded out at both ends.
    private func landscape(width: CGFloat) -> some View {
        let drawn = width * Self.overscan

        return Image("mountains")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: drawn, height: drawn / Self.aspect)
            .frame(width: width)
            .clipped()
            // Faded at both ends. The bottom hides the artwork's own frame
            // edge, which cuts the lake off in a dead straight line and
            // against a soft mesh reads as a photograph pasted on. The top is
            // the seam with the canvas, and it reaches full opacity early on
            // purpose: the painted sun begins 35% down the artwork, and a
            // softer fade veiled the top of it. It can afford to be abrupt
            // because the illustration's own sky up there is already almost
            // exactly the canvas.
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.5), location: 0.09),
                        .init(color: .white.opacity(0.95), location: 0.20),
                        .init(color: .white, location: 0.30),
                        .init(color: .white, location: 0.84),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            // The illustration is lit for a pale sky; at full strength on the
            // dark canvas it turns into a glowing slab, so it drops back to a
            // suggestion of a horizon there.
            .opacity(scheme == .dark ? 0.34 : 1)
            .saturation(scheme == .dark ? 0.72 : 1)
    }

    private func note(_ text: String, size: CGSize, at unit: CGPoint, tilt: Double) -> some View {
        Text(text)
            .font(EquiHand.font(17))
            .foregroundStyle(AppTheme.inkSecondary.opacity(0.78))
            .multilineTextAlignment(.leading)
            .lineSpacing(-1)
            .rotationEffect(.degrees(tilt))
            .position(x: unit.x * size.width, y: unit.y * size.height)
    }

    private func arrow(size: CGSize, from: CGPoint, to: CGPoint, control: CGPoint) -> some View {
        EquiHandArrow(from: from, to: to, control: control)
            .stroke(
                AppTheme.inkSecondary.opacity(0.5),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
            .frame(width: size.width, height: size.height)
    }

    private func bubble(size: CGSize) -> some View {
        Text("Your next adventure,\nsimpler with Equi.")
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(AppTheme.ink.opacity(0.82))
            .lineSpacing(1.5)
            .padding(.horizontal, 13)
            .padding(.top, 9)
            .padding(.bottom, 18)
            .background {
                EquiBubbleShape()
                    .fill(AppTheme.accent.opacity(scheme == .dark ? 0.22 : 0.14))
                    .overlay {
                        EquiBubbleShape()
                            .stroke(AppTheme.accent.opacity(0.2), lineWidth: 0.75)
                    }
            }
            // The burst sits above the bubble's shoulder, so it — not the
            // bubble — is the top of this element. It sets the clearance to
            // the subtitle above.
            .overlay(alignment: .topTrailing) {
                EquiSparkBurst()
                    .rotationEffect(.degrees(28))
                    .offset(x: 14, y: -12)
            }
            .position(x: size.width * 0.755, y: size.height * 0.255)
    }
}
