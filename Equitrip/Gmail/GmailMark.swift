//
//  GmailMark.swift
//  Equitrip
//

import SwiftUI

/// Gmail's envelope, drawn rather than bundled.
///
/// The settings row for a Google connection has to carry Google's mark — an
/// SF Symbol envelope in the app's ink reads as "email", not as "your Gmail
/// account", and the difference matters on a row that is about to ask for
/// access to somebody's mailbox. Drawn as paths so it stays crisp at 32pt and
/// there's no asset to keep in step with the brand guidelines.
struct GmailMark: View {
    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            ZStack {
                piece(4, rect).fill(Color(red: 0.773, green: 0.133, blue: 0.122)) // #C5221F
                piece(0, rect).fill(Color(red: 0.259, green: 0.522, blue: 0.957)) // #4285F4
                piece(1, rect).fill(Color(red: 0.204, green: 0.659, blue: 0.325)) // #34A853
                piece(2, rect).fill(Color(red: 0.984, green: 0.737, blue: 0.016)) // #FBBC04
                piece(3, rect).fill(Color(red: 0.918, green: 0.263, blue: 0.208)) // #EA4335
            }
        }
        .aspectRatio(88.0 / 66.0, contentMode: .fit)
    }

    /// Source viewBox is 52 42 88 66; every point below is in that space.
    private func piece(_ index: Int, _ rect: CGRect) -> Path {
        let s = min(rect.width / 88, rect.height / 66)
        let dx = rect.midX - 44 * s
        let dy = rect.midY - 33 * s
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: (x - 52) * s + dx, y: (y - 42) * s + dy)
        }

        var path = Path()
        switch index {
        case 0: // left bar
            path.move(to: p(58, 108))
            path.addLine(to: p(72, 108))
            path.addLine(to: p(72, 74))
            path.addLine(to: p(52, 59))
            path.addLine(to: p(52, 102))
            path.addCurve(to: p(58, 108), control1: p(52, 105.32), control2: p(54.69, 108))
        case 1: // right bar
            path.move(to: p(120, 108))
            path.addLine(to: p(134, 108))
            path.addCurve(to: p(140, 102), control1: p(137.32, 108), control2: p(140, 105.31))
            path.addLine(to: p(140, 59))
            path.addLine(to: p(120, 74))
        case 2: // right flap
            path.move(to: p(120, 48))
            path.addLine(to: p(120, 74))
            path.addLine(to: p(140, 59))
            path.addLine(to: p(140, 51))
            path.addCurve(to: p(125.6, 43.8), control1: p(140, 43.58), control2: p(131.53, 39.35))
        case 3: // the M
            path.move(to: p(72, 74))
            path.addLine(to: p(72, 48))
            path.addLine(to: p(96, 66))
            path.addLine(to: p(120, 48))
            path.addLine(to: p(120, 74))
            path.addLine(to: p(96, 92))
        default: // left flap
            path.move(to: p(52, 51))
            path.addLine(to: p(52, 59))
            path.addLine(to: p(72, 74))
            path.addLine(to: p(72, 48))
            path.addLine(to: p(66.4, 43.8))
            path.addCurve(to: p(52, 51), control1: p(60.46, 39.35), control2: p(52, 43.58))
        }
        path.closeSubpath()
        return path
    }
}
