//
//  IslandToastView.swift
//  Equitrip
//

import SwiftUI

/// A toast that drips out of the Dynamic Island as a droplet of island-black,
/// turns to liquid glass as it swells into the card, and is pulled back in
/// the same way.
///
/// The drip is one explicit outline, not a blur-and-threshold "goo" filter.
/// Goo needs the island drawn at its real width to fuse with, and that width
/// varies by model. A thin neck also falls below the threshold and snaps early.
/// Instead, the outline is traced row by row: a concave fillet flaring into the
/// island's flat bottom edge, a neck, and a smooth blend into the droplet's
/// shoulders through a second fillet. One vertical gradient covers the whole shape, island-black at the
/// top and fading toward see-through at the droplet as it becomes glass, so
/// the real `.glassEffect` card underneath shows through without a seam. The
/// motion follows rit3zh/expo-dynamic-notifications.
struct IslandToastView<Content: View>: View {
    let motion: ToastMotion
    let island: CGRect
    let containerWidth: CGFloat
    let cardSize: CGSize
    let dragOffset: Double
    @ViewBuilder let content: Content

    var body: some View {
        let shape = geometry

        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: shape.card.width, height: shape.card.height)
                .glassEffect(.regular, in: .rect(cornerRadius: shape.radius, style: .continuous))
                .opacity(Self.progress(motion.tint, from: 0.06, to: 0.88))
                .shadow(color: .black.opacity(0.16 * min(max(motion.expand, 0), 1)), radius: 22, y: 10)
                .overlay {
                    content
                        .frame(width: cardSize.width, height: cardSize.height)
                        .scaleEffect(contentScale(for: shape))
                        .blur(radius: 8 * (1 - reveal))
                        .opacity(reveal)
                        .allowsHitTesting(reveal > 0.5)
                }
                .position(x: shape.card.midX, y: shape.card.midY)

            Canvas { context, _ in drawDrip(in: &context, shape) }
                .frame(width: containerWidth, height: shape.canvasHeight)
                .allowsHitTesting(false)
        }
    }

    private var reveal: Double { min(max(motion.reveal, 0), 1) }

    /// Content grows in from slightly small, and rides the card's own
    /// overshoot so the text doesn't look pinned inside a swelling card.
    private func contentScale(for shape: Drip) -> Double {
        let overshoot = min(max(shape.card.width / cardSize.width - 1, 0), 0.2)
        return (0.88 + 0.12 * reveal) + overshoot * reveal
    }

    // MARK: - Drip

    private func drawDrip(in context: inout GraphicsContext, _ shape: Drip) {
        guard shape.card.width > 0.5, shape.card.height > 0.5 else { return }
        let glassiness = Self.progress(motion.tint, from: 0.06, to: 0.88)

        var path = RoundedRectangle(cornerRadius: shape.radius, style: .continuous).path(in: shape.card)
        // Also while the droplet still overlaps the island's edge, before
        // it has a neck, so it bulges out of the island rather than hanging
        // from it at square corners.
        if shape.neckHalfWidth > 0.4 || shape.card.minY < island.maxY + 1 {
            path = path.union(bridge(shape))
        }

        // Island-black where it leaves the island, whatever the droplet has
        // turned into by then, fading over a short run below it. That's what
        // makes it read as poured out of the island, not a grey ball under it.
        context.fill(path, with: .linearGradient(
            Gradient(colors: [.black, .black.opacity(1 - glassiness)]),
            startPoint: CGPoint(x: shape.card.midX, y: island.maxY),
            endPoint: CGPoint(x: shape.card.midX, y: island.maxY + 20)
        ))
    }

    /// The neck, from just inside the island down into the droplet, traced
    /// as a half-width profile. It starts a few points up inside the cutout,
    /// where it's hidden, so the join never shows a seam.
    private func bridge(_ shape: Drip) -> Path {
        let rect = shape.card
        let cx = rect.midX
        let islandBottom = island.maxY
        let top = islandBottom - 6
        let neck = shape.neckHalfWidth
        // Whatever hangs directly below the island, neck or droplet, gets
        // the fillet. Kept well inside the flat part of the smallest island's
        // bottom edge: its corners are continuous curves that start rising
        // early, and a flare that reaches them peeks out as two small ears.
        // It also scales with the drip, so a droplet just emerging doesn't
        // sit on a wide lip.
        let base = max(neck, dropletHalfWidth(shape, at: islandBottom + 6))
        let islandFillet = min(18, max(24 - base, 0), 2 + base)

        // Where the neck meets the droplet: a circle tangent to both the neck
        // and the droplet's rounded top, so the side flows into the droplet
        // instead of meeting it at a crease.
        let r = min(shape.radius, rect.width / 2, rect.height / 2)
        let corner = CGPoint(x: rect.width / 2 - r, y: rect.minY + r)
        let f = min(14, r)
        let dx = neck + f - corner.x
        let fillet = CGPoint(x: neck + f, y: corner.y - max((r + f) * (r + f) - dx * dx, 0).squareRoot())
        let touch = CGPoint(
            x: corner.x + (fillet.x - corner.x) * r / (r + f),
            y: corner.y + (fillet.y - corner.y) * r / (r + f)
        )
        let bottom = min(max(touch.y + 1, islandBottom + 1), rect.maxY)

        func halfWidth(at y: CGFloat) -> CGFloat {
            // The fillet leaves the island a little above its estimated
            // bottom edge, so its widest point is always behind the cutout.
            let edge = islandBottom - 1
            var h = neck
            if y <= edge {
                h = base + islandFillet
            } else if y < edge + islandFillet {
                // A quarter circle, concave, tangent to the island's bottom
                // edge and to whatever hangs below it.
                let dy = y - (edge + islandFillet)
                h = base + islandFillet - (islandFillet * islandFillet - dy * dy).squareRoot()
            }
            if y >= fillet.y, y <= touch.y {
                let dy = y - fillet.y
                h = max(h, fillet.x - max(f * f - dy * dy, 0).squareRoot())
            } else if y > touch.y {
                h = max(h, dropletHalfWidth(shape, at: y))
            }
            return h
        }

        let step: CGFloat = 0.5
        var left: [CGPoint] = []
        var y = top
        while y < bottom {
            left.append(CGPoint(x: cx - halfWidth(at: y), y: y))
            y += step
        }
        left.append(CGPoint(x: cx - halfWidth(at: bottom), y: bottom))

        var path = Path()
        path.addLines(left + left.reversed().map { CGPoint(x: 2 * cx - $0.x, y: $0.y) })
        path.closeSubpath()
        return path
    }

    /// The droplet's half-width at a given height, treating its corners as
    /// circular.
    private func dropletHalfWidth(_ shape: Drip, at y: CGFloat) -> CGFloat {
        let rect = shape.card
        guard y >= rect.minY, y <= rect.maxY else { return 0 }
        let r = min(shape.radius, rect.width / 2, rect.height / 2)
        let flat = rect.width / 2 - r
        let fromEdge = min(y - rect.minY, rect.maxY - y)
        guard fromEdge < r else { return rect.width / 2 }
        let dy = r - fromEdge
        return flat + (r * r - dy * dy).squareRoot()
    }

    // MARK: - Geometry

    struct Drip {
        var card: CGRect
        var radius: CGFloat
        /// Zero once the neck has snapped.
        var neckHalfWidth: CGFloat
        var canvasHeight: CGFloat
    }

    /// Where the droplet and neck are for the current motion. The droplet
    /// grows as it falls, stretches tall while the neck is at its thickest,
    /// and turns into the card as `expand` rises.
    private var geometry: Drip {
        let dropSize: CGFloat = 64
        let cardTop = island.maxY + DynamicIslandMetrics.gap
        let cardCenterY = cardTop + cardSize.height / 2
        let expand = motion.expand
        let drop = motion.drop

        let grow = 1 - pow(1 - min(max(drop / 0.7, 0), 1), 1.25)
        let neck = Self.neckProfile(drop / 0.82, rise: 1.6, fall: 1.4)
        let stretch = 1 + 0.22 * neck
        let droplet = dropSize * grow

        let width = min(Self.mix(expand, droplet / stretch, cardSize.width), containerWidth - 20)
        let height = max(Self.mix(expand, droplet * stretch, cardSize.height), 0)
        let cardRadius = GlassToastContent.radius(forHeight: cardSize.height)
        let radius = max(min(Self.mix(expand, droplet / 2, cardRadius), min(width, height) / 2), 0)

        let originY = island.maxY - island.height * 0.34
        // A drag moves the card, not the droplet: it fades out as the card
        // collapses, so a flicked-away card is still pulled into the island.
        let centerY = Self.mix(drop, originY, cardCenterY) + dragOffset * min(max(expand, 0), 1)
            // The droplet sags while the neck is thick, so it hangs below the
            // island on a funnel-shaped neck, a teardrop rather than a pill
            // flush against the island. Gone by the time the neck snaps.
            + 14 * neck

        // Thinner than the droplet so it reads as a neck, and capped so the
        // flare at the top stays on the island's flat bottom edge.
        let neckHalfWidth = min(15, width * 0.42) * neck

        return Drip(
            card: CGRect(x: containerWidth / 2 - width / 2, y: centerY - height / 2, width: max(width, 0), height: height),
            radius: radius,
            neckHalfWidth: neckHalfWidth,
            canvasHeight: cardTop + cardSize.height + 96
        )
    }

    private static func mix(_ t: Double, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private static func progress(_ value: Double, from: Double, to: Double) -> Double {
        min(max((value - from) / (to - from), 0), 1)
    }

    /// A bump that rises from 0 to a peak of 1 and falls back to 0 over
    /// 0…1: how thick the neck between island and droplet is as it falls.
    /// Past 1 the neck has snapped, and the droplet hangs free.
    private static func neckProfile(_ progress: Double, rise: Double, fall: Double) -> Double {
        let t = min(max(progress, 0), 1)
        guard t > 0, t < 1 else { return 0 }
        let peak = rise / (rise + fall)
        let normal = pow(peak, rise) * pow(1 - peak, fall)
        return pow(t, rise) * pow(1 - t, fall) / normal
    }
}

/// Where the Dynamic Island is, estimated from the safe area.
///
/// There's no API for the island's frame. Its height and its position,
/// a fixed distance above the bottom of the top safe area inset, hold on every
/// iPhone that has one. The top inset is also the only way to tell an island
/// from a notch (47–50pt) or from no cutout at all (iPad, landscape). The width
/// doesn't hold: 126pt through the 17 Pro, about 95pt on the 18 Pro. So `size`
/// is narrower than any of them. It's where the drip starts, hidden behind the
/// hardware, never drawn as the island itself.
enum DynamicIslandMetrics {
    static let size = CGSize(width: 88, height: 36.67)
    /// Between the island's bottom edge and the card's top edge.
    static let gap: CGFloat = 30

    static func islandFrame(width: CGFloat, topInset: CGFloat) -> CGRect? {
        guard topInset >= 51 else { return nil }
        let top = max(topInset - size.height - 11.67, 11)
        return CGRect(x: (width - size.width) / 2, y: top, width: size.width, height: size.height)
    }

    static func cardWidth(for width: CGFloat) -> CGFloat {
        min(width - 24, 400)
    }
}
