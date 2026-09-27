//
//  ScenarioTimingCard.swift
//  Equitrip
//

import SwiftUI

/// When and where the what-if weather hits, drawn over the bookings it
/// could hit.
///
/// The time is a band on a 24-hour track that's dragged, stretched from
/// either end, or dropped by tapping the track — with the trip's bookings
/// sitting on the same track at their start times. Two sliders for "starts
/// at" and "lasts" used to do this, and neither showed the thing that
/// matters: whether the storm lands on the heritage walk or two hours after
/// it. A booking inside the band takes its what-if risk colour; one the
/// weather can't reach stays grey, so an indoor dinner in the middle of a
/// cloudburst reads as the good news it is.
struct ScenarioTimingCard: View {
    @Binding var scenario: TwinScenario
    let days: [Date]
    let places: [WeatherFusion.Place]
    let markers: [Marker]

    /// A booking on the track.
    struct Marker: Identifiable, Hashable {
        let id: UUID
        let title: String
        let day: Date
        /// Hours since local midnight.
        let hour: Double
        let symbol: String
        /// Its what-if risk; nil while the simulation catches up.
        let risk: RiskLevel?
    }

    private struct DragBase {
        let start: Int
        let duration: Double
    }

    @State private var dragBase: DragBase?
    /// Measured, so the lane knows how many rows its markers pack into
    /// before the track is laid out.
    @State private var trackWidth: CGFloat = 340

    private let trackHeight: CGFloat = 34
    private let markerSize: CGFloat = 18
    private let laneGap: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            menuRow("Day", value: dayLabel) {
                Picker("Day", selection: dayIndex) {
                    Text("Every day of the trip").tag(-1)
                    ForEach(days.indices, id: \.self) { index in
                        Text(DateFormatter.cached("EEEE d MMM").string(from: days[index])).tag(index)
                    }
                }
            }

            Hairline()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(windowLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .contentTransition(.numericText())
                    Spacer(minLength: 8)
                    Text("\(Int(scenario.durationHours)) h")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .contentTransition(.numericText())
                }
                .animation(.snappy, value: scenario.startHour)
                .animation(.snappy, value: scenario.durationHours)

                track
                axis

                Text(hint)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.vertical, 14)

            Hairline()

            menuRow("Where", value: placeLabel) {
                Picker("Where", selection: placeIndex) {
                    Text("Everywhere on the trip").tag(-1)
                    ForEach(places.indices, id: \.self) { index in
                        Text(places[index].name).tag(index)
                    }
                }
            }

            if scenario.center != nil {
                Hairline()
                HStack(spacing: 12) {
                    Text("Reach")
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                    Slider(value: $scenario.radiusKm, in: 3...80, step: 1)
                        .tint(AppTheme.accent)
                    Text("\(Int(scenario.radiusKm)) km")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
                .frame(minHeight: 50)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
        .animation(.snappy, value: scenario.center)
    }

    // MARK: - Track

    private var start: Double { Double(scenario.startHour) }
    private var end: Double { start + scenario.durationHours }
    /// Hours the event runs past midnight.
    private var overflow: Double { max(0, end - 24) }

    /// Bookings in a lane above the band rather than on it: on "every day" a
    /// trip's worth of them covered the band's handles.
    private var track: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let hourWidth = width / 24
            let rows = markerRows(width: width)
            let laneHeight = laneHeight(rows: rows.count)
            let bandWidth = (min(end, 24) - start) * hourWidth
            let handleWidth = min(30, max(12, bandWidth / 2))

            ZStack(alignment: .topLeading) {
                ForEach([6, 12, 18], id: \.self) { hour in
                    Rectangle()
                        .fill(AppTheme.cardStroke.opacity(0.07))
                        .frame(width: 1, height: laneHeight + trackHeight)
                        .offset(x: CGFloat(hour) * hourWidth)
                }

                // The band's hours, carried up through the lane, so which
                // bookings are "inside" reads without lining them up by eye.
                Rectangle()
                    .fill(tint.opacity(0.06))
                    .frame(width: max(0, bandWidth), height: laneHeight)
                    .offset(x: start * hourWidth)

                ForEach(Array(rows.enumerated()), id: \.offset) { row, markers in
                    ForEach(markers) { marker in
                        markerView(marker)
                            .position(
                                x: markerX(marker, width: width),
                                y: CGFloat(row) * (markerSize + 2) + markerSize / 2
                            )
                    }
                }

                Group {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.canvasTop)
                        .frame(height: trackHeight)
                        .contentShape(.rect)
                        .gesture(SpatialTapGesture().onEnded { value in
                            centre(on: value.location.x / hourWidth)
                        })

                    // On "every day", a storm past midnight is still going
                    // the next morning — and that morning is on this track.
                    if overflow > 0, scenario.targetDay == nil {
                        band(width: overflow * hourWidth, faded: true)
                            .allowsHitTesting(false)
                    }

                    band(width: bandWidth, faded: false)
                        .offset(x: start * hourWidth)
                        .highPriorityGesture(drag(hourWidth) { base, steps in
                            (min(23, max(0, base.start + steps)), base.duration)
                        })

                    handle(width: handleWidth)
                        .position(x: start * hourWidth, y: trackHeight / 2)
                        .highPriorityGesture(drag(hourWidth) { base, steps in
                            let fixedEnd = base.start + Int(base.duration)
                            let newStart = min(fixedEnd - 1, max(0, max(fixedEnd - 24, base.start + steps)))
                            return (newStart, Double(fixedEnd - newStart))
                        })

                    handle(width: handleWidth)
                        .position(x: min(end, 24) * hourWidth, y: trackHeight / 2)
                        .highPriorityGesture(drag(hourWidth) { base, steps in
                            (base.start, min(24, max(1, base.duration + Double(steps))))
                        })
                }
                .frame(width: width, height: trackHeight, alignment: .topLeading)
                .offset(y: laneHeight)
            }
        }
        .frame(height: laneHeight(rows: markerRows(width: trackWidth).count) + trackHeight)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trackWidth = $0 }
        .accessibilityElement()
        .accessibilityLabel("When the weather hits")
        .accessibilityValue(windowLabel)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: scenario.startHour = min(23, scenario.startHour + 1)
            case .decrement: scenario.startHour = max(0, scenario.startHour - 1)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Make it longer") { scenario.durationHours = min(24, scenario.durationHours + 1) }
        .accessibilityAction(named: "Make it shorter") { scenario.durationHours = max(1, scenario.durationHours - 1) }
    }

    private func laneHeight(rows: Int) -> CGFloat {
        rows == 0 ? 0 : CGFloat(rows) * (markerSize + 2) - 2 + laneGap
    }

    private func markerX(_ marker: Marker, width: CGFloat) -> CGFloat {
        max(markerSize / 2, min(width - markerSize / 2, marker.hour * width / 24))
    }

    /// Packs markers into as few rows as keep them from touching, earliest
    /// first — at most three, after which a row takes the overlap.
    private func markerRows(width: CGFloat) -> [[Marker]] {
        var rows: [[Marker]] = []
        var lastX: [CGFloat] = []
        for marker in visibleMarkers.sorted(by: { $0.hour < $1.hour }) {
            let x = markerX(marker, width: width)
            if let row = lastX.firstIndex(where: { x - $0 >= markerSize + 1 }) {
                rows[row].append(marker)
                lastX[row] = x
            } else if rows.count < 3 {
                rows.append([marker])
                lastX.append(x)
            } else {
                let row = lastX.indices.min { lastX[$0] < lastX[$1] } ?? 0
                rows[row].append(marker)
                lastX[row] = x
            }
        }
        return rows
    }

    private var tint: Color {
        scenario.temperature != nil && scenario.rainIntensity == nil ? Palette.amberDeep : Palette.blue
    }

    private func band(width: CGFloat, faded: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(tint.opacity(faded ? 0.08 : 0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tint.opacity(faded ? 0.3 : 0.7), style: StrokeStyle(lineWidth: 1.5, dash: faded ? [4, 3] : []))
            }
            .frame(width: max(8, width), height: trackHeight)
            .contentShape(.rect)
    }

    private func handle(width: CGFloat) -> some View {
        Capsule()
            .fill(.white)
            .frame(width: 6, height: 20)
            .overlay { Capsule().strokeBorder(tint, lineWidth: 1.5) }
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            .frame(width: width, height: trackHeight)
            .contentShape(.rect)
    }

    private func markerView(_ marker: Marker) -> some View {
        let isHit = isInside(marker.hour) && (marker.risk?.isNotable ?? false)
        let colour = isHit ? (marker.risk?.tint ?? tint) : AppTheme.inkTertiary
        return Image(systemName: marker.symbol)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(isHit ? .white : colour)
            .frame(width: markerSize, height: markerSize)
            .background(Circle().fill(isHit ? AnyShapeStyle(colour) : AnyShapeStyle(AppTheme.card)))
            .overlay { Circle().strokeBorder(colour.opacity(isHit ? 0 : 0.5), lineWidth: 1) }
            .animation(.snappy, value: isHit)
    }

    private var axis: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack {
                Text("12 AM").frame(maxWidth: .infinity, alignment: .leading)
                Text("6 AM").position(x: w * 0.25, y: 7)
                Text("Noon").position(x: w * 0.5, y: 7)
                Text("6 PM").position(x: w * 0.75, y: 7)
                Text("12 AM").frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.system(size: 10.5, weight: .medium))
        .foregroundStyle(AppTheme.inkTertiary)
        .frame(height: 14)
        .accessibilityHidden(true)
    }

    // MARK: - Dragging

    private func drag(_ hourWidth: CGFloat, _ step: @escaping (DragBase, Int) -> (Int, Double)) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let base = dragBase ?? DragBase(start: scenario.startHour, duration: scenario.durationHours)
                if dragBase == nil { dragBase = base }
                let (newStart, newDuration) = step(base, Int((value.translation.width / hourWidth).rounded()))
                guard newStart != scenario.startHour || newDuration != scenario.durationHours else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                scenario.startHour = newStart
                scenario.durationHours = newDuration
            }
            .onEnded { _ in dragBase = nil }
    }

    private func centre(on hour: Double) {
        let newStart = Int((hour - scenario.durationHours / 2).rounded())
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.snappy) { scenario.startHour = min(23, max(0, newStart)) }
    }

    // MARK: - Words

    private var visibleMarkers: [Marker] {
        guard let day = scenario.targetDay else { return markers }
        return markers.filter { Calendar.current.isDate($0.day, inSameDayAs: day) }
    }

    private func isInside(_ hour: Double) -> Bool {
        if hour >= start, hour < end { return true }
        return scenario.targetDay == nil && hour < overflow
    }

    private var hint: String {
        let inside = visibleMarkers.filter { isInside($0.hour) }
        let exposed = inside.filter { $0.risk?.isNotable ?? false }.count
        let scope = scenario.targetDay == nil ? "on any day" : "that day"
        if visibleMarkers.isEmpty { return "No bookings with a start time \(scope)." }
        if inside.isEmpty { return "None of your bookings start inside it \(scope). Drag it over one, or tap the track." }
        let count = inside.count == 1 ? "1 booking starts" : "\(inside.count) bookings start"
        switch exposed {
        case 0: return "\(count) inside it, and none of them are exposed to it."
        case inside.count: return "\(count) inside it. \(inside.count == 1 ? "It's" : "All are") exposed."
        default: return "\(count) inside it; \(exposed) of them exposed."
        }
    }

    private var windowLabel: String {
        let formatter = DateFormatter.cached("h a")
        let midnight = Calendar.current.startOfDay(for: Date())
        let from = formatter.string(from: midnight.addingTimeInterval(start * 3600))
        let endHour = end.truncatingRemainder(dividingBy: 24)
        let to = end == 24 ? "midnight" : formatter.string(from: midnight.addingTimeInterval(endHour * 3600))
        return end > 24 ? "\(from) – \(to) next day" : "\(from) – \(to)"
    }

    private var dayLabel: String {
        scenario.targetDay.map { DateFormatter.cached("EEE d MMM").string(from: $0) } ?? "Every day"
    }

    private var placeLabel: String {
        guard let centre = scenario.center else { return "Everywhere" }
        return places.first { $0.point == centre }?.name ?? "Custom spot"
    }

    private var dayIndex: Binding<Int> {
        Binding(
            get: { scenario.targetDay.flatMap { day in days.firstIndex { Calendar.current.isDate($0, inSameDayAs: day) } } ?? -1 },
            set: { index in withAnimation(.snappy) { scenario.targetDay = days.indices.contains(index) ? days[index] : nil } }
        )
    }

    private var placeIndex: Binding<Int> {
        Binding(
            get: { scenario.center.flatMap { centre in places.firstIndex { $0.point == centre } } ?? -1 },
            set: { index in withAnimation(.snappy) { scenario.center = places.indices.contains(index) ? places[index].point : nil } }
        )
    }

    private func menuRow<Content: View>(_ title: String, value: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14.5, weight: .medium))
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: 8)
            Menu {
                content()
            } label: {
                HStack(spacing: 5) {
                    Text(value)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .font(.system(size: 14.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .contentShape(.rect)
            }
        }
        .frame(minHeight: 50)
    }
}
