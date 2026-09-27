//
//  TwinMap.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// The twin, on a map: every booking where it is, coloured by its risk; the
/// dependencies between them drawn as lines that thicken and redden as
/// trouble flows along them; the weather at each place, flagged where a
/// Weather Union station is measuring it; ground reports pinned to the
/// places they name; and, in a what-if, the storm's footprint.
///
/// The lines are the point. A booking turning red is a forecast; a red line
/// running from a flooded transfer to a dinner across town is the twin
/// showing its working.
struct TwinMap: View {
    let twin: TripTwin
    let result: TwinResult?
    let weather: [String: PlaceWeather]
    let digest: SignalDigest
    let scenario: TwinScenario
    @Binding var selection: UUID?
    /// The place whose ground reports are open, keyed like `signalClusters`.
    @Binding var signalSelection: String?
    @Binding var camera: MapCameraPosition

    var body: some View {
        let positions = displayPositions()

        Map(position: $camera) {
            if let centre = scenario.center, !scenario.isLive {
                MapCircle(center: centre.coordinate, radius: scenario.radiusKm * 1600)
                    .foregroundStyle(stormTint.opacity(0.08))
                MapCircle(center: centre.coordinate, radius: scenario.radiusKm * 600)
                    .foregroundStyle(stormTint.opacity(0.16))
                    .stroke(stormTint.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }

            ForEach(twin.edges) { edge in
                if let a = positions[edge.from], let b = positions[edge.to], GeoPoint(a).distance(to: GeoPoint(b)) > 0.05 {
                    let flow = result?.edgeFlow[edge.id] ?? 0
                    MapPolyline(coordinates: [a, b])
                        .stroke(
                            flowColor(flow),
                            style: StrokeStyle(lineWidth: 2 + 6 * min(flow * 2, 1), lineCap: .round, lineJoin: .round, dash: flow < 0.03 ? [3, 5] : [])
                        )
                }
            }

            ForEach(Array(weather.values)) { place in
                Annotation("", coordinate: place.point.offset(km: 0.9, bearing: 315).coordinate, anchor: .bottom) {
                    WeatherPlaceMarker(place: place)
                }
                .annotationTitles(.hidden)
            }

            ForEach(signalClusters, id: \.name) { cluster in
                Annotation("", coordinate: cluster.point.coordinate, anchor: .center) {
                    SignalClusterMarker(count: cluster.count, category: cluster.category, official: cluster.official)
                        .scaleEffect(signalSelection == cluster.name ? 1.15 : 1)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selection = nil
                                signalSelection = signalSelection == cluster.name ? nil : cluster.name
                            }
                        }
                }
                .annotationTitles(.hidden)
            }

            ForEach(twin.nodes) { node in
                if let coordinate = positions[node.id] {
                    Annotation(node.item.title, coordinate: coordinate, anchor: .center) {
                        TwinNodePin(
                            node: node,
                            outcome: result?.outcomes[node.id],
                            isSelected: selection == node.id
                        )
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                signalSelection = nil
                                selection = selection == node.id ? nil : node.id
                            }
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    private var stormTint: Color {
        (scenario.temperature ?? 0) >= 38 && scenario.rainIntensity == nil ? Palette.amberDeep : Palette.indigo
    }

    private func flowColor(_ flow: Double) -> Color {
        switch flow {
        case ..<0.03: AppTheme.inkTertiary.opacity(0.45)
        case ..<0.15: Palette.amber
        case ..<0.35: Palette.amberDeep
        default: AppTheme.danger
        }
    }

    /// Where each pin is drawn. Bookings that share a spot (three nights at
    /// one hotel) or were only placed approximately fan out in a small ring,
    /// so none hides under another.
    private func displayPositions() -> [UUID: CLLocationCoordinate2D] {
        var result: [UUID: CLLocationCoordinate2D] = [:]
        let grouped = Dictionary(grouping: twin.nodes) {
            "\(($0.place.point.latitude * 2000).rounded()),\(($0.place.point.longitude * 2000).rounded())"
        }
        for (_, group) in grouped {
            guard group.count > 1 else {
                if let only = group.first { result[only.id] = only.place.point.coordinate }
                continue
            }
            for (index, node) in group.enumerated() {
                let ring = 0.25 + 0.12 * Double(index / 6)
                result[node.id] = node.place.point.offset(km: ring, bearing: Double(index) * 60 + 20).coordinate
            }
        }
        return result
    }

    private struct SignalCluster {
        let name: String
        let point: GeoPoint
        let count: Int
        let category: SocialSignal.Category
        let official: Bool
    }

    /// Reports grouped by the place they name, pinned just off that place.
    private var signalClusters: [SignalCluster] {
        Dictionary(grouping: digest.signals, by: { $0.place.lowercased() }).compactMap { key, signals in
            let point = weather.values.first { $0.name.lowercased() == key }?.point
                ?? twin.nodes.first { $0.place.locality?.lowercased() == key }?.place.point
                ?? twin.destination.point
            let top = Dictionary(grouping: signals, by: \.category)
                .max { $0.value.reduce(0) { $0 + $1.strength } < $1.value.reduce(0) { $0 + $1.strength } }?.key ?? .heavyRain
            return SignalCluster(
                name: key,
                point: point.offset(km: 1.1, bearing: 60),
                count: signals.count,
                category: top,
                official: signals.contains { $0.source.isOfficial }
            )
        }
    }
}

// MARK: - Markers

/// A booking on the map: its glyph, on its risk.
struct TwinNodePin: View {
    let node: TwinNode
    let outcome: NodeOutcome?
    var isSelected = false

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var risk: RiskLevel { outcome?.risk ?? .calm }
    private var tint: Color { outcome == nil ? AppTheme.inkTertiary : (risk == .calm ? node.item.kind.tint : risk.tint) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if risk >= .warning, !reduceMotion {
                    Circle()
                        .fill(risk.tint.opacity(0.3))
                        .frame(width: 34, height: 34)
                        .scaleEffect(pulse ? 2 : 1)
                        .opacity(pulse ? 0 : 0.9)
                }

                Circle()
                    .fill(node.place.isApproximate ? AnyShapeStyle(.white) : AnyShapeStyle(tint))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle().strokeBorder(
                            node.place.isApproximate ? tint : .white,
                            style: StrokeStyle(lineWidth: node.place.isApproximate ? 2 : 2.5, dash: node.place.isApproximate ? [3, 2] : [])
                        )
                    }
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Image(systemName: node.item.symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(node.place.isApproximate ? tint : .white)

                if let outcome, outcome.order > 1, outcome.risk.isNotable {
                    Text("\(min(outcome.order, 3))")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 15, height: 15)
                        .background(Palette.amberDeep, in: .circle)
                        .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                        .offset(x: 12, y: -12)
                }
            }
            .scaleEffect(isSelected ? 1.25 : 1)

            if isSelected || (outcome?.risk ?? .calm) >= .warning {
                HStack(spacing: 4) {
                    Text(node.item.title)
                        .lineLimit(1)
                    if let outcome, outcome.risk.isNotable {
                        Text(TwinFormat.percent(outcome.pAffected))
                            .foregroundStyle(outcome.risk.tint)
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial, in: .capsule)
                .frame(maxWidth: 160)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
        .accessibilityElement()
        .accessibilityLabel("\(node.item.title), \(risk.label)")
    }
}

/// The weather at one place, as a glass tag on the map.
struct WeatherPlaceMarker: View {
    let place: PlaceWeather

    var body: some View {
        let reading = place.current
        let hour = place.upcomingHours(1).first
        let condition = reading?.condition ?? hour?.condition ?? .partlyCloudy

        HStack(spacing: 5) {
            Image(systemName: condition.symbol(isDay: reading?.isDay ?? true))
                .font(.system(size: 13))
                .symbolRenderingMode(.multicolor)
            Text(TwinFormat.temperature(reading?.temperature ?? hour?.temperature))
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            if let rain = reading?.rainIntensity, rain >= 0.5 {
                Text("\(TwinFormat.rain(rain))mm")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.blue)
            }
            if reading?.isStationBacked == true {
                Text("WU")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Palette.red, in: .capsule)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

/// Ground reports about one place: how many, and what they're mostly about.
struct SignalClusterMarker: View {
    let count: Int
    let category: SocialSignal.Category
    var official = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: official ? "exclamationmark.shield.fill" : "bubble.left.fill")
                .font(.system(size: 10, weight: .bold))
            Image(systemName: category.symbol)
                .font(.system(size: 10, weight: .bold))
            Text("\(count)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(official ? AppTheme.danger : category.tint, in: .capsule)
        .overlay { Capsule().strokeBorder(.white, lineWidth: 1.5) }
        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
    }
}
