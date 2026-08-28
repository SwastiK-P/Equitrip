//
//  FlightLookupService.swift
//  Equitrip
//

import Foundation

/// Turns a flight number into a route, scheduled times and a live status.
///
/// Backed by AviationStack. Two things about their free tier shape this:
/// `flight_date` is a paid-plan parameter (asking for it burns a request and
/// then 403s), and a single flight number can return a stack of codeshares
/// under other airlines' names — so we filter to the exact IATA code rather
/// than trusting the first row.
@MainActor
final class FlightLookupService {
    static let shared = FlightLookupService()

    enum LookupError: LocalizedError {
        case notConfigured
        case notFound
        case network
        /// The API answered, but refused. Its own message is far more useful
        /// than anything we'd invent — plan limits, bad key, quota.
        case service(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Live flight lookup isn't set up yet."
            case .notFound: "No live data for that flight number right now."
            case .network: "Couldn't reach the flight data service."
            case .service(let message): message
            }
        }
    }

    private let session = URLSession(configuration: .ephemeral)

    /// - Parameter bookingDate: Not sent to the API — the free plan rejects a
    ///   date filter. It's used to reconcile the result afterwards: the row we
    ///   get back is whichever instance of that flight number is current, so
    ///   its *time of day* is trustworthy for the booking but its live status
    ///   belongs to a different day's flight.
    func lookup(number: String, bookingDate: Date) async throws -> FlightDetails {
        let normalised = Self.normalise(number)
        guard !normalised.isEmpty else { throw LookupError.notFound }
        guard FlightConfig.isConfigured else { throw LookupError.notConfigured }

        var components = URLComponents(string: "https://api.aviationstack.com/v1/flights")!
        components.queryItems = [
            .init(name: "access_key", value: FlightConfig.aviationStackKey),
            .init(name: "flight_iata", value: normalised)
        ]

        guard let url = components.url else { throw LookupError.network }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw LookupError.network
        }

        let decoded: AviationStackResponse
        do {
            decoded = try JSONDecoder().decode(AviationStackResponse.self, from: data)
        } catch {
            throw LookupError.network
        }

        // Plan limits and bad keys arrive as a 200-shaped body with an error
        // object as often as they do a 4xx, so this is checked before status.
        if let apiError = decoded.error {
            throw LookupError.service(apiError.message ?? "The flight service refused that request.")
        }

        guard let rows = decoded.data, !rows.isEmpty else { throw LookupError.notFound }

        // Codeshares come back under the marketing carrier's name; the row
        // whose own IATA matches what was asked for is the real one.
        let match = rows.first { Self.normalise($0.flight?.iata ?? "") == normalised } ?? rows[0]

        return match.asFlightDetails(
            fallbackNumber: Self.display(number),
            bookingDate: bookingDate,
            checkedAt: Date()
        )
    }

    /// "6e 5312", "6E-5312" and "6E5312" should all reach the same flight.
    static func normalise(_ raw: String) -> String {
        raw.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    /// A light-touch display form — "6E5312" back to "6E 5312" — for anywhere
    /// a raw, unspaced code would look like a typo.
    static func display(_ raw: String) -> String {
        let clean = normalise(raw)
        guard let splitIndex = clean.firstIndex(where: { $0.isNumber }) else { return clean }
        let prefix = clean[..<splitIndex]
        let suffix = clean[splitIndex...]
        return prefix.isEmpty ? clean : "\(prefix) \(suffix)"
    }
}

// MARK: - Wire format

private struct AviationStackResponse: Decodable {
    let data: [Flight]?
    let error: APIError?

    struct APIError: Decodable {
        let code: String?
        let message: String?
    }

    struct Flight: Decodable {
        struct Endpoint: Decodable {
            let airport: String?
            let timezone: String?
            let iata: String?
            let terminal: String?
            let gate: String?
            let delay: Int?
            let scheduled: String?
            let estimated: String?
        }
        struct Airline: Decodable { let name: String? }
        struct Number: Decodable { let iata: String? }

        let flight_status: String?
        let departure: Endpoint?
        let arrival: Endpoint?
        let airline: Airline?
        let flight: Number?

        func asFlightDetails(fallbackNumber: String, bookingDate: Date, checkedAt: Date) -> FlightDetails {
            // Estimated beats scheduled once a flight is moving — it's the
            // time someone actually needs to be at the gate for.
            let rawDeparture = Self.parse(departure?.estimated) ?? Self.parse(departure?.scheduled)
            let rawArrival = Self.parse(arrival?.estimated) ?? Self.parse(arrival?.scheduled)

            // The row is whichever instance of this flight number is current,
            // which is rarely the day the group is flying. A flight number's
            // time of day is stable, so those get carried onto the booking's
            // own date; the live status doesn't survive the move.
            let sameDay = rawDeparture.map { Calendar.current.isDate($0, inSameDayAs: bookingDate) } ?? false

            let resolvedStatus: FlightDetails.Status = sameDay
                ? (flight_status.flatMap(FlightDetails.Status.init(rawValue:)) ?? .unknown)
                : .scheduled

            return FlightDetails(
                number: fallbackNumber,
                airlineName: airline?.name,
                departureAirport: departure?.iata,
                departureAirportName: departure?.airport,
                departureCity: departure?.timezone.flatMap(Self.city),
                departureTerminal: departure?.terminal,
                departureGate: departure?.gate,
                arrivalAirport: arrival?.iata,
                arrivalAirportName: arrival?.airport,
                arrivalCity: arrival?.timezone.flatMap(Self.city),
                arrivalTerminal: arrival?.terminal,
                scheduledDeparture: Self.moveTimeOfDay(rawDeparture, onto: bookingDate),
                // An overnight flight lands the day after it leaves; keep that
                // gap rather than folding the arrival back onto day one.
                scheduledArrival: Self.moveTimeOfDay(
                    rawArrival,
                    onto: bookingDate,
                    addingDays: Self.overnightOffset(from: rawDeparture, to: rawArrival)
                ),
                departureDelay: sameDay ? departure?.delay : nil,
                status: resolvedStatus,
                lastChecked: checkedAt
            )
        }

        /// Keeps the clock time, changes the calendar day.
        private static func moveTimeOfDay(_ source: Date?, onto day: Date, addingDays offset: Int = 0) -> Date? {
            guard let source else { return nil }
            let calendar = Calendar.current
            let time = calendar.dateComponents([.hour, .minute], from: source)
            let base = calendar.date(byAdding: .day, value: offset, to: day) ?? day
            return calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: base)
        }

        private static func overnightOffset(from departure: Date?, to arrival: Date?) -> Int {
            guard let departure, let arrival else { return 0 }
            let calendar = Calendar.current
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: departure),
                to: calendar.startOfDay(for: arrival)
            ).day ?? 0
            return max(0, days)
        }

        /// The API gives no city field, but the IANA timezone carries one —
        /// "Asia/Kolkata" → "Kolkata" is close enough to be useful under an
        /// airport code, and it's the only city signal on offer.
        private static func city(_ timezone: String) -> String? {
            timezone.split(separator: "/").last
                .map { $0.replacingOccurrences(of: "_", with: " ") }
        }

        private static func parse(_ text: String?) -> Date? {
            guard let text else { return nil }
            return ISO8601DateFormatter().date(from: text)
                ?? ISO8601DateFormatter.withFractionalSeconds.date(from: text)
        }
    }
}

private extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
