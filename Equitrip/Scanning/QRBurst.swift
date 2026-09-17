//
//  QRBurst.swift
//  Equitrip
//

import SwiftUI

/// The four corners of a code, as the camera saw it.
///
/// Named in the code's own frame rather than the screen's — `topLeft` is the
/// corner by the code's top-left finder pattern, wherever that has ended up on
/// screen. That's what makes a QR photographed upside-down draw upside-down.
struct QuadCorners: Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    /// An axis-aligned square, for the place the code settles before it goes.
    static func square(_ rect: CGRect) -> QuadCorners {
        QuadCorners(
            topLeft: CGPoint(x: rect.minX, y: rect.minY),
            topRight: CGPoint(x: rect.maxX, y: rect.minY),
            bottomRight: CGPoint(x: rect.maxX, y: rect.maxY),
            bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
        )
    }

    var centre: CGPoint {
        CGPoint(
            x: (topLeft.x + topRight.x + bottomRight.x + bottomLeft.x) / 4,
            y: (topLeft.y + topRight.y + bottomRight.y + bottomLeft.y) / 4
        )
    }

    /// Mean edge length — what a module's size is derived from, since a
    /// perspective quad has no single width.
    var span: CGFloat {
        let edges = [
            hypot(topRight.x - topLeft.x, topRight.y - topLeft.y),
            hypot(bottomRight.x - topRight.x, bottomRight.y - topRight.y),
            hypot(bottomLeft.x - bottomRight.x, bottomLeft.y - bottomRight.y),
            hypot(topLeft.x - bottomLeft.x, topLeft.y - bottomLeft.y)
        ]
        return edges.reduce(0, +) / 4
    }

    /// A point inside the quad, in code coordinates (0…1 across, 0…1 down).
    ///
    /// Bilinear rather than a true homography. A projective map would be more
    /// correct for a code held at a steep angle, but it needs an inverse and a
    /// per-point divide, and at the angles anyone actually scans from the two
    /// are indistinguishable — this runs a few hundred times a frame.
    func point(u: CGFloat, v: CGFloat) -> CGPoint {
        let top = CGPoint(
            x: topLeft.x + (topRight.x - topLeft.x) * u,
            y: topLeft.y + (topRight.y - topLeft.y) * u
        )
        let bottom = CGPoint(
            x: bottomLeft.x + (bottomRight.x - bottomLeft.x) * u,
            y: bottomLeft.y + (bottomRight.y - bottomLeft.y) * u
        )
        return CGPoint(x: top.x + (bottom.x - top.x) * v, y: top.y + (bottom.y - top.y) * v)
    }

    /// One module of the code, as a four-sided cell of this quad — optionally
    /// swollen about its own centre and moved.
    ///
    /// The scaling happens after the warp, not before, so a module that has
    /// broken away keeps the shape it had while it was part of the code. That
    /// is what makes the burst look like the code coming apart rather than
    /// like squares being emitted from where a code used to be.
    func cell(
        u0: CGFloat, v0: CGFloat,
        u1: CGFloat, v1: CGFloat,
        about anchor: CGPoint,
        scale: CGFloat,
        bloom: CGFloat,
        offset: CGVector
    ) -> (path: Path, centre: CGPoint) {
        // Projected about the anchor, so position and size scale together —
        // this is the perspective step, and doing it to all four corners at
        // once is what keeps the module a module rather than a growing dot.
        var corners = [
            point(u: u0, v: v0),
            point(u: u1, v: v0),
            point(u: u1, v: v1),
            point(u: u0, v: v1)
        ].map { corner in
            CGPoint(
                x: anchor.x + (corner.x - anchor.x) * scale + offset.dx,
                y: anchor.y + (corner.y - anchor.y) * scale + offset.dy
            )
        }

        let middle = CGPoint(
            x: corners.reduce(0) { $0 + $1.x } / 4,
            y: corners.reduce(0) { $0 + $1.y } / 4
        )

        // The glow is grown about the module's own centre, not the anchor, so
        // it stays concentric with the square it belongs to instead of sliding
        // off it as the projection pushes outward.
        if bloom != 1 {
            corners = corners.map { corner in
                CGPoint(
                    x: middle.x + (corner.x - middle.x) * bloom,
                    y: middle.y + (corner.y - middle.y) * bloom
                )
            }
        }

        var path = Path()
        for (index, corner) in corners.enumerated() {
            if index == 0 { path.move(to: corner) } else { path.addLine(to: corner) }
        }
        path.closeSubpath()

        return (path, middle)
    }

    static func lerp(_ a: QuadCorners, _ b: QuadCorners, _ t: CGFloat) -> QuadCorners {
        func mix(_ p: CGPoint, _ q: CGPoint) -> CGPoint {
            CGPoint(x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t)
        }
        return QuadCorners(
            topLeft: mix(a.topLeft, b.topLeft),
            topRight: mix(a.topRight, b.topRight),
            bottomRight: mix(a.bottomRight, b.bottomRight),
            bottomLeft: mix(a.bottomLeft, b.bottomLeft)
        )
    }
}

/// The scanned code lifting off the page and coming apart.
///
/// Four beats:
///
/// 1. **Land.** The code is redrawn in white *exactly where the camera found
///    it* — same place, same rotation, same skew. This is the whole
///    acknowledgement: the app is showing you it read that code, on that
///    table, at that angle. Drawing a neat square in the middle of the screen
///    instead says "something was scanned", which is a different and much
///    weaker claim.
/// 2. **Travel.** The quad straightens and flies to the centre, settling a
///    little smaller than it arrived.
/// 3. **Burst.** Every module becomes a particle and leaves, outward,
///    accelerating and *growing*. The growth is the trick: a square moving
///    away from the middle while getting bigger is what a square moving toward
///    your eye looks like, so the code appears to come through the camera
///    rather than merely scatter.
/// 4. **Whiteout.** The nearest particles grow past the frame, and the next
///    screen is revealed out of the white they leave behind.
///
/// All of it covers a network round trip. Looking a code up takes a moment,
/// and a spinner over a frozen viewfinder makes that moment feel like a fault.
struct QRBurst: View {
    /// The modules of the code that was scanned.
    let matrix: [[Bool]]
    /// Where the camera found it.
    let found: QuadCorners
    /// Where it settles before coming apart.
    let target: CGRect
    /// Fired once the screen is white, so the presenter can swap what's
    /// underneath before anything fades back in.
    var onWhiteout: () -> Void

    @State private var start = Date()
    @State private var didStart = false

    // MARK: Timing

    /// Four beats, just under two seconds end to end.
    ///
    /// Slower than the reflex says it should be, and deliberately. The scan is
    /// the only moment in the app where something the camera found becomes
    /// something the app has — and it's covering a network call anyway, so the
    /// time is being spent either way. Run quick, all four beats blur into a
    /// flash and the code you actually scanned is never legible on screen; run
    /// at this pace, each beat is separately readable: it landed *there*, it
    /// came to the middle, it let go, it filled the screen.
    ///
    /// `form` earns its own beat rather than overlapping the travel. The code
    /// used to paint on *while* it was already flying to the middle, which
    /// meant the one moment worth seeing — the white code sitting exactly on
    /// the real one, at the real one's angle — never actually happened. It has
    /// to land, be still, and be recognised before it goes anywhere.
    private static let form: Double = 0.36
    private static let travel: Double = 0.58
    // The pause is doing work, not padding. It's the only frame where the code
    // is square, still and centred — the one chance to read it as the code you
    // scanned rather than as something in motion — and coming straight off the
    // travel into the burst threw that away.
    private static let hold: Double = 0.28
    private static let fly: Double = 1.30

    /// How long a module takes to cross the frame — the burst's *speed*, held
    /// separate from `fly`, which is only how long the burst is allowed to run.
    ///
    /// They were the same number, and that made the two impossible to tune
    /// independently: depth was a fraction of the window, so stretching the
    /// window slowed every particle down in exact proportion. Lengthening the
    /// burst made it more sluggish rather than longer. Pinning the pace to
    /// seconds means the modules keep the speed they had and simply carry on
    /// coming — further out, larger, for longer — which is the difference
    /// between a slower animation and more of one.
    private static let flightPace: Double = 0.92

    private static var travelStart: Double { form }
    private static var burstStart: Double { form + travel + hold }
    private static var total: Double { form + travel + hold + fly }

    /// The white ramps in over the tail of the burst rather than after it, so
    /// the particles are still moving when the screen fills. A flash that
    /// waits for them to land reads as two separate events.
    ///
    /// Held back to well past halfway. Starting it at the midpoint washed the
    /// burst out before the near modules had grown into anything — the whole
    /// effect happened behind a white veil that was already at half strength.
    private static var whiteStart: Double { burstStart + fly * 0.6 }

    /// When the screen is white enough to hand over.
    private static var handover: Double { whiteStart + (total - whiteStart) * 0.85 }

    var body: some View {
        // Capped at 60fps rather than left on the display link. There are a
        // few hundred squares to place per frame, over a live camera preview
        // that is already asking a lot — a 120Hz Canvas on top of that is how
        // you drop frames in the one animation that has to be smooth.
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                draw(in: &context, size: size, t: timeline.date.timeIntervalSince(start))
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            start = Date()

            BurstHaptics.play(form: Self.form, travel: Self.travel, hold: Self.hold, fly: Self.fly)

            Task {
                try? await Task.sleep(for: .seconds(Self.handover))
                onWhiteout()
            }
        }
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize, t: Double) {
        let veil = min(
            0.82,
            easeOut(progress(t, 0, Self.form + Self.travel)) * 0.5
                + easeOut(progress(t, Self.burstStart, Self.total)) * 0.32
        )
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(veil)))

        let particles = Self.particles(for: matrix)
        guard !particles.isEmpty else { return }

        // Ease-in-out on the way in, so it leaves the table gently and arrives
        // without a skid.
        let quad = QuadCorners.lerp(
            found,
            .square(target),
            easeInOut(progress(t, Self.travelStart, Self.travelStart + Self.travel))
        )
        let reach = max(size.width, size.height) * 1.2

        // Each square is drawn twice: a soft oversized halo, then the solid
        // module on top. A real blur — `addFilter(.blur)` over a full-screen
        // layer — is a filter pass per frame on top of a camera preview, and
        // costs far more than the glow is worth. Two fills read the same at
        // this speed and cost nothing.
        plot(particles, in: &context, t: t, quad: quad, reach: reach, halo: true)
        plot(particles, in: &context, t: t, quad: quad, reach: reach, halo: false)

        let white = easeIn(progress(t, Self.whiteStart, Self.total))
        if white > 0 {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(white)))
        }
    }

    /// Draws every module as its own cell of the quad.
    ///
    /// Not an axis-aligned square at the module's centre, which is what this
    /// did first and why the result didn't read as a QR: a code seen at an
    /// angle has a rotated, sheared grid, and drawing upright squares along it
    /// leaves gaps at every edge. The pattern dissolves into a field of dots —
    /// the finder squares stop being squares, the dense runs stop being runs,
    /// and the one thing the shape has to say ("this is *your* code") is
    /// exactly what's lost. Taking all four corners of each cell through the
    /// same warp makes the modules tile edge to edge at any angle, so it reads
    /// as the code lying on the table, which is the whole point of putting it
    /// where the camera found it.
    private func plot(
        _ particles: [Particle],
        in context: inout GraphicsContext,
        t: Double,
        quad: QuadCorners,
        reach: CGFloat,
        halo: Bool
    ) {
        // The code draws itself in from the middle out, over its own beat and
        // before anything moves. Slow enough to watch it happen, which is the
        // point — this is the app showing you it read *that* code, on that
        // table, at that angle.
        let landed = progress(t, 0, Self.form)
        let bounds = CGRect(x: -reach, y: -reach, width: reach * 3, height: reach * 3)

        for particle in particles {
            let entrance = easeOut(progress(landed, particle.radius * 0.55, 1))
            guard entrance > 0.001 else { continue }

            // Seconds since this module let go, not a fraction of the burst.
            let elapsed = max(0, t - (Self.burstStart + particle.delay))

            // While it's still seated there's nothing for a halo to do but
            // bleed across the module next door and turn the pattern to mush.
            if halo && elapsed <= 0 { continue }

            // Unclamped on purpose: past 1 the fastest modules are through the
            // lens and still growing, which is what keeps the tail of the
            // burst moving instead of freezing into a held frame.
            let travelled = elapsed / Self.flightPace

            // Perspective, rather than "move outward and also get bigger".
            //
            // The first version pushed every module along its own radius at
            // its own speed and grew it on a separate curve, and the result
            // was a mandala: rings of evenly-spaced squares with a hole where
            // the code used to be. Giving each module a depth instead and
            // projecting it — one over one-minus-z, the same arithmetic a
            // camera does — fixes both faults at once. Position and size come
            // from the same number, so the whole thing reads as *approach*;
            // and because the modules keep their arrangement while it happens,
            // what flies past you is recognisably the code, not confetti.
            // Slightly *decelerating* in depth rather than accelerating. One
            // over one-minus-z is already a curve that does nothing for most
            // of its range and everything at the end; squaring the input on
            // top of that put the entire visible effect into the last few
            // frames, which were the ones already under the white.
            let z = min(0.96, pow(travelled, 0.85) * particle.rate)
            let projection = 1 / (1 - z)

            // A little lateral wander, so a hundred modules travelling the
            // same depth don't move in lockstep.
            let drift = CGVector(
                dx: particle.drift.dx * min(1.4, travelled) * 26,
                dy: particle.drift.dy * min(1.4, travelled) * 26
            )

            let cell = quad.cell(
                u0: particle.u0, v0: particle.v0,
                u1: particle.u1, v1: particle.v1,
                about: quad.centre,
                scale: projection * (0.55 + 0.45 * entrance),
                bloom: halo ? 1.7 : 1,
                offset: drift
            )
            guard bounds.contains(cell.centre) else { continue }

            context.fill(
                cell.path,
                with: .color(.white.opacity(entrance * (halo ? 0.24 : 1)))
            )
        }
    }

    // MARK: - Curves

    /// 0 before `from`, 1 after `to`, linear between.
    private func progress(_ t: Double, _ from: Double, _ to: Double) -> Double {
        guard to > from else { return t >= to ? 1 : 0 }
        return min(1, max(0, (t - from) / (to - from)))
    }

    private func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    private func easeIn(_ x: Double) -> Double { x * x }
    private func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }

    // MARK: - Particles

    private struct Particle {
        /// The module's own cell, 0…1 across and down. All four edges, not a
        /// centre point: they're taken through `QuadCorners` every frame, so a
        /// module keeps both its place *and its shape* in the code however the
        /// quad is being warped.
        let u0: CGFloat
        let v0: CGFloat
        let u1: CGFloat
        let v1: CGFloat
        /// Distance from the middle, 0…1. Drives both the paint-on order and
        /// the order the code comes apart in.
        let radius: Double
        /// How fast this module comes at you, 0…1 of the way to the lens.
        ///
        /// Skewed low on purpose: most modules barely leave, a handful come
        /// right past your eye. An even spread makes a uniform expanding
        /// texture, which is the one thing an explosion never looks like.
        let rate: Double
        /// A small sideways wander, so modules at the same depth don't move as
        /// a rigid sheet.
        let drift: CGVector
        /// When it leaves, in seconds after the burst begins.
        let delay: Double
    }

    /// Built once per matrix and cached.
    ///
    /// Deterministic — seeded off each module's own coordinates rather than
    /// `random()` — because `Canvas` redraws sixty times a second, and a
    /// particle that picks a new direction every frame is noise, not motion.
    private static func particles(for matrix: [[Bool]]) -> [Particle] {
        let signature = checksum(matrix)
        if let cached = cache, cached.checksum == signature { return cached.particles }

        let n = max(1, matrix.count)
        var built: [Particle] = []
        built.reserveCapacity(320)

        // Every dark module, with no thinning. Dropping every other one
        // halved the fill count and destroyed the thing being drawn — a QR
        // with holes punched through its finder patterns is a texture, not a
        // code. A join link is a version-2 or -3 symbol, so this is a few
        // hundred cells; the halo pass is skipped while they're seated, which
        // is where the cost would otherwise have shown.
        for row in 0..<n {
            for column in 0..<matrix[row].count where matrix[row][column] {
                let u = (Double(column) + 0.5) / Double(n)
                let v = (Double(row) + 0.5) / Double(n)
                let radius = min(1, hypot(u - 0.5, v - 0.5) / 0.707)
                let step = 1 / Double(n)

                // Two independent hashes per module, so direction jitter and
                // speed don't correlate into visible banding.
                let a = hash(column &* 73_856_093 ^ row &* 19_349_663)
                let b = hash(column &* 83_492_791 ^ row &* 12_582_917)

                built.append(
                    Particle(
                        u0: u - step / 2,
                        v0: v - step / 2,
                        u1: u + step / 2,
                        v1: v + step / 2,
                        radius: radius,
                        // Skewed hard to the slow end, so there's a dense core
                        // of modules that barely move and a scattering that
                        // come right past the lens. Cubing it left too few in
                        // the second group for any of them to register.
                        rate: 0.12 + pow(a, 2.4) * 0.84,
                        drift: CGVector(dx: (b - 0.5) * 2, dy: (hash(row &* 31 &+ column) - 0.5) * 2),
                        // Outermost leaves first: the code peels apart from its
                        // edges rather than everything going at once.
                        delay: (1 - radius) * 0.15 + b * 0.05
                    )
                )
            }
        }

        cache = (signature, built)
        return built
    }

    private nonisolated(unsafe) static var cache: (checksum: Int, particles: [Particle])?

    private static func checksum(_ matrix: [[Bool]]) -> Int {
        var value = 17
        for (row, line) in matrix.enumerated() {
            for (column, on) in line.enumerated() where on {
                value = value &* 31 &+ (row &* 131 &+ column)
            }
        }
        return value
    }

    /// A cheap integer hash folded into 0…1.
    private static func hash(_ value: Int) -> Double {
        var x = UInt64(bitPattern: Int64(value)) &* 0x9E37_79B9_7F4A_7C15
        x ^= x >> 30
        x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27
        return Double(x % 10_000) / 10_000
    }
}
