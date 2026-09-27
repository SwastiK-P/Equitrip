//
//  ScenarioDial.swift
//  Equitrip
//

import SwiftUI

/// One what-if parameter as a round dial: a three-quarter arc turned with a
/// finger, the value in the middle, what it means underneath.
///
/// Round because four of them fit a phone's width as a 2×2 grid, where four
/// full-width sliders stacked into a form a screen and a half tall — and a
/// dial's fill reads as "how much" at a glance across the grid. The arc's
/// start is the dial's floor, which for every parameter means "as
/// forecast"; the gap at the bottom keeps a turn past the top from wrapping
/// round to nothing.
struct ScenarioDial: View {
    let title: String
    let symbol: String
    let tint: Color
    /// 0–1 around the arc.
    @Binding var fraction: Double
    /// Discrete positions, so a turn clicks from value to value.
    let steps: Int
    /// The value as the middle of the dial shows it; nil at the floor.
    let value: String?
    let unit: String
    /// What the value means, under the dial ("Very heavy", "Streets flooded").
    let caption: String?

    @State private var isDragging = false

    private let sweep = 0.75
    private let startAngle = 135.0
    private let lineWidth: CGFloat = 8

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                let radius = (side - lineWidth) / 2
                let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

                ZStack {
                    Circle()
                        .trim(from: 0, to: sweep)
                        .stroke(AppTheme.cardStroke.opacity(0.08), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(startAngle))

                    Circle()
                        .trim(from: 0, to: sweep * fraction)
                        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(startAngle))

                    thumb
                        .position(point(at: fraction, centre: centre, radius: radius))
                }
                // The arc eases to a preset's value, but follows a finger
                // exactly — an animation under a drag reads as lag.
                .animation(isDragging ? nil : .snappy, value: fraction)
                .overlay {
                    VStack(spacing: 1) {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(value == nil ? AppTheme.inkTertiary : tint)
                        Text(value ?? "–")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(value == nil ? AppTheme.inkTertiary : AppTheme.ink)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(value == nil ? " " : unit)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .frame(width: radius * 1.3)
                    .animation(.snappy, value: value)
                }
                .frame(width: side, height: side)
                .position(centre)
                // Only the ring turns the dial. Four of these fill most of a
                // screen, and a whole-disc gesture caught every scroll that
                // started on one.
                .contentShape(RingShape(width: 40))
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            isDragging = true
                            turn(to: drag.location, centre: CGPoint(x: side / 2, y: side / 2))
                        }
                        .onEnded { _ in isDragging = false }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 104)

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(caption ?? "As forecast")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue(value.map { "\($0) \(unit), \(caption ?? "")" } ?? "As forecast")
        .accessibilityAdjustableAction { direction in
            let step = 1 / Double(max(1, steps))
            switch direction {
            case .increment: fraction = min(1, fraction + step)
            case .decrement: fraction = max(0, fraction - step)
            @unknown default: break
            }
        }
    }

    private var thumb: some View {
        Circle()
            .fill(.white)
            .frame(width: 19, height: 19)
            .overlay { Circle().strokeBorder(tint, lineWidth: 2.5) }
            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
            .scaleEffect(isDragging ? 1.15 : 1)
            .animation(.snappy, value: isDragging)
    }

    private func point(at fraction: Double, centre: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (startAngle + 360 * sweep * fraction) * .pi / 180
        return CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
    }

    /// The finger's angle, measured from the arc's start. In the gap at the
    /// bottom it sticks to whichever end it's nearer, so dragging past the
    /// top of the scale can't flip it to zero.
    private func turn(to location: CGPoint, centre: CGPoint) {
        let degrees = atan2(location.y - centre.y, location.x - centre.x) * 180 / .pi
        var along = (degrees - startAngle).truncatingRemainder(dividingBy: 360)
        if along < 0 { along += 360 }
        let span = 360 * sweep
        var next: Double
        if along <= span {
            next = along / span
        } else {
            next = fraction > 0.5 ? 1 : 0
        }
        let count = Double(max(1, steps))
        next = (next * count).rounded() / count
        guard next != fraction else { return }
        NSLog("TWINPERF dial %@ -> %f at %@", title, next, NSCoder.string(for: location)) // TEMP
        UISelectionFeedbackGenerator().selectionChanged()
        fraction = next
    }
}

/// A band around a circle's edge, for hit-testing a dial's ring.
private struct RingShape: Shape {
    let width: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: 5, dy: 5)
        return Path(ellipseIn: inset).strokedPath(StrokeStyle(lineWidth: width))
    }
}
