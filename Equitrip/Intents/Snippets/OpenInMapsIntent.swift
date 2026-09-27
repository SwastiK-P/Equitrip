//
//  OpenInMapsIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Directions" on the what's-next card: the booking's place, in Maps.
///
/// Directions are Maps' job, and Equitrip only knows a booking's place as the
/// words on the booking — a hotel's name, a restaurant's — so this hands Maps
/// those words, with the trip's destination after them so "Taj" means the one
/// in Goa. It opens Maps rather than the app, which is the point: the person
/// asking "what's next" on the way out of a hotel wants the route.
struct OpenInMapsIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Directions"
    static let isDiscoverable = false

    @Parameter(title: "Place")
    var place: String

    init() {}

    init(place: String) {
        self.place = place
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [URLQueryItem(name: "q", value: place)]
        guard let url = components.url else { throw IntentFailure.bookingNotFound }
        return .result(opensIntent: OpenURLIntent(url))
    }
}
