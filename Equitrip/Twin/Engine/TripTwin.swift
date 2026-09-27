//
//  TripTwin.swift
//  Equitrip
//

import Foundation

/// One booking as the twin sees it: what it is, where, when it's exposed,
/// and which weather place answers for it.
struct TwinNode: Identifiable, Hashable {
    let item: ItineraryItem
    let exposure: WeatherExposure
    let window: DateInterval
    let place: TwinGeocoder.Place
    /// The `PlaceWeather` id this booking reads its weather from.
    let weatherPlaceID: String

    var id: UUID { item.id }
    var isTransport: Bool { [.flight, .train, .drive].contains(item.kind) }
}

/// A dependency between two bookings: if the first goes wrong, the second can.
struct TwinEdge: Identifiable, Hashable {
    enum Kind: String, Hashable {
        /// Getting to a flight or train: the road to the airport.
        case transfer
        /// Arriving somewhere, and the next thing there.
        case arrival
        /// Two things back to back, where running late on one eats the other.
        case sequence

        var label: String {
            switch self {
            case .transfer: "has to reach"
            case .arrival: "has to arrive for"
            case .sequence: "runs into"
            }
        }

        /// How strongly trouble carries across, before slack is considered.
        var strength: Double {
            switch self {
            case .transfer: 1.0
            case .arrival: 0.8
            case .sequence: 0.45
            }
        }
    }

    let from: UUID
    let to: UUID
    let kind: Kind
    /// Minutes between the first finishing and the second starting.
    let slack: Double

    var id: String { "\(from)>\(to)" }
}

/// The trip as a graph the weather can move through.
///
/// Built from the itinerary alone — no new data is asked of anyone. The
/// edges are the dependencies a group already lives with but never writes
/// down: the taxi that has to reach the airport, the flight that has to land
/// before check-in, the boat tour that runs into dinner. They're what lets
/// the twin say *why* a sunny-day dinner is at risk: not because of the
/// weather where the dinner is, but because the ferry before it won't sail.
struct TripTwin {
    let tripID: UUID
    let destination: TwinGeocoder.Place
    let nodes: [TwinNode]
    let edges: [TwinEdge]
    /// The places weather is fetched for — bookings within 4 km share one.
    let weatherPlaces: [WeatherFusion.Place]
    /// The last flight or train of the trip: the one whose loss strands people.
    let homeboundID: UUID?

    func node(_ id: UUID) -> TwinNode? { nodes.first { $0.id == id } }
    func incoming(_ id: UUID) -> [TwinEdge] { edges.filter { $0.to == id } }
    func outgoing(_ id: UUID) -> [TwinEdge] { edges.filter { $0.from == id } }

    /// Every distinct place name on the trip, most useful first — what social
    /// signals are searched and matched on.
    var placeNames: [String] {
        var names = [destination.name]
        if let locality = destination.locality { names.append(locality) }
        let counted = Dictionary(grouping: nodes.compactMap { $0.place.isApproximate ? nil : $0.place.locality }, by: { $0 })
            .sorted { $0.value.count > $1.value.count }
            .map(\.key)
        names += counted
        var seen = Set<String>()
        return names.filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    // MARK: - Building

    static func build(trip: Trip, destination: TwinGeocoder.Place, places: [UUID: TwinGeocoder.Place]) -> TripTwin {
        // Weather places: cluster booking locations within 4 km, capped at six
        // (nearest the destination first) so a trip costs a bounded number of requests.
        var clusters: [WeatherFusion.Place] = [WeatherFusion.Place(id: "dest", name: destination.name, point: destination.point)]
        let located = trip.items.compactMap { item -> (UUID, TwinGeocoder.Place)? in
            places[item.id].map { (item.id, $0) }
        }
        .sorted { $0.1.point.distance(to: destination.point) < $1.1.point.distance(to: destination.point) }

        var clusterFor: [UUID: String] = [:]
        for (id, place) in located {
            if let near = clusters.first(where: { $0.point.distance(to: place.point) <= 4 }) {
                clusterFor[id] = near.id
            } else if clusters.count < 6 {
                let cluster = WeatherFusion.Place(id: "p\(clusters.count)", name: place.locality ?? place.name, point: place.point)
                clusters.append(cluster)
                clusterFor[id] = cluster.id
            } else {
                let nearest = clusters.min { $0.point.distance(to: place.point) < $1.point.distance(to: place.point) }!
                clusterFor[id] = nearest.id
            }
        }

        let nodes = trip.items.sorted { Trip.chronological($0, $1) }.map { item -> TwinNode in
            let exposure = WeatherExposure.of(item)
            let place = places[item.id] ?? TwinGeocoder.Place(
                name: destination.name, point: destination.point, locality: destination.locality, isApproximate: true
            )
            return TwinNode(
                item: item,
                exposure: exposure,
                window: exposure.window(for: item),
                place: place,
                weatherPlaceID: clusterFor[item.id] ?? "dest"
            )
        }

        let homebound = nodes.last { $0.item.kind == .flight || $0.item.kind == .train }
            .flatMap { node -> UUID? in
                // Only the trip's last day counts as "going home".
                let lastDay = nodes.map(\.item.day).max()
                return node.item.day == lastDay ? node.id : nil
            }

        return TripTwin(
            tripID: trip.id,
            destination: destination,
            nodes: nodes,
            edges: edges(for: nodes),
            weatherPlaces: clusters,
            homeboundID: homebound
        )
    }

    private static func edges(for nodes: [TwinNode]) -> [TwinEdge] {
        var edges: [TwinEdge] = []
        let calendar = Calendar.current

        func slack(_ a: TwinNode, _ b: TwinNode) -> Double {
            guard a.item.time != nil, b.item.time != nil else { return 180 }
            return max(0, b.window.start.timeIntervalSince(a.window.end) / 60)
        }

        for (index, node) in nodes.enumerated() {
            let sameDayAfter = nodes[(index + 1)...].filter { calendar.isDate($0.item.day, inSameDayAs: node.item.day) }
            let sameDayBefore = nodes[..<index].filter { calendar.isDate($0.item.day, inSameDayAs: node.item.day) }

            if node.isTransport {
                // Arriving: the next thing that isn't another leg of the journey.
                if let next = sameDayAfter.first(where: { !$0.isTransport || $0.item.kind == .drive && node.item.kind != .drive }),
                   next.window.start.timeIntervalSince(node.window.end) < 10 * 3600 {
                    edges.append(TwinEdge(from: node.id, to: next.id, kind: .arrival, slack: slack(node, next)))
                }
                // Check-in the same day depends on getting there at all.
                if node.item.kind != .drive,
                   let stay = sameDayAfter.first(where: { $0.item.kind == .stay }),
                   !edges.contains(where: { $0.from == node.id && $0.to == stay.id }) {
                    edges.append(TwinEdge(from: node.id, to: stay.id, kind: .arrival, slack: max(120, slack(node, stay))))
                }
            }

            // The road to a flight or train.
            if node.item.kind == .flight || node.item.kind == .train,
               let road = sameDayBefore.last(where: { $0.item.kind == .drive }),
               node.window.start.timeIntervalSince(road.window.end) < 6 * 3600 {
                edges.append(TwinEdge(from: road.id, to: node.id, kind: .transfer, slack: slack(road, node)))
            }

            // Back to back: under ninety minutes between two timed things.
            if !node.isTransport, node.item.time != nil,
               let next = sameDayAfter.first(where: { !$0.isTransport && $0.item.kind != .stay && $0.item.time != nil }) {
                let gap = slack(node, next)
                if gap < 90, !edges.contains(where: { $0.to == next.id }) {
                    edges.append(TwinEdge(from: node.id, to: next.id, kind: .sequence, slack: gap))
                }
            }
        }
        return edges
    }
}
