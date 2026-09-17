//
//  ChatAttachment.swift
//  Equitrip
//

import SwiftUI

/// The component a chat message carries, beyond its text.
///
/// Components that point at trip data — a booking, the balances — store an id
/// or nothing at all, and are drawn from the trip as it is when you look. A
/// booking card that froze its price at the moment somebody shared it would be
/// the chat arguing with the ledger, and the ledger is the one that's right.
/// Nothing here holds an amount of money.
enum ChatAttachment: Equatable {
    case photo(Photo)
    case place(Place)
    case booking(itemID: UUID)
    case poll(Poll)
    case meetup(Meetup)
    case checklist(Checklist)
    case balances
    /// A kind a newer build sent. Shown as a row asking for an update rather
    /// than dropped, so nobody answers a question they can't see.
    case unsupported(kind: String)

    struct Photo: Equatable {
        var url: URL
        /// Pixel size, so the bubble is laid out at the right shape before the
        /// image arrives instead of jumping when it does.
        var width: Double
        var height: Double

        var aspectRatio: Double {
            guard width > 0, height > 0 else { return 4.0 / 3.0 }
            // Clamped: a panorama or a long screenshot would otherwise make a
            // bubble a sliver or a skyscraper.
            return min(1.9, max(0.62, width / height))
        }
    }

    struct Place: Equatable {
        var name: String
        var subtitle: String
        var latitude: Double
        var longitude: Double
    }

    nonisolated struct Option: Codable, Equatable, Identifiable, Hashable {
        var id: String
        var text: String

        init(id: String = UUID().uuidString, text: String) {
            self.id = id
            self.text = text
        }
    }

    struct Poll: Equatable {
        var question: String
        var options: [Option]
        var allowsMultiple: Bool
    }

    struct Meetup: Equatable {
        var title: String
        var date: Date
        var place: String?
    }

    struct Checklist: Equatable {
        var title: String
        var items: [Option]
    }

    /// The three answers a meetup takes. Stored as their raw values in
    /// `message_responses.choices`.
    enum RSVP: String, CaseIterable, Identifiable {
        case going, maybe, no

        var id: String { rawValue }

        var label: String {
            switch self {
            case .going: "Going"
            case .maybe: "Maybe"
            case .no: "Can't"
            }
        }

        var symbol: String {
            switch self {
            case .going: "checkmark.circle.fill"
            case .maybe: "questionmark.circle.fill"
            case .no: "xmark.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .going: AppTheme.positive
            case .maybe: Palette.amber
            case .no: AppTheme.inkTertiary
            }
        }
    }

    // MARK: Presentation

    var kind: String {
        switch self {
        case .photo: "photo"
        case .place: "place"
        case .booking: "booking"
        case .poll: "poll"
        case .meetup: "meetup"
        case .checklist: "checklist"
        case .balances: "balances"
        case .unsupported(let kind): kind
        }
    }

    /// Whether people answer it, which is what puts it on the Plans shelf and
    /// gives it a response row in `ChatService`.
    var takesResponses: Bool {
        switch self {
        case .poll, .meetup, .checklist: true
        default: false
        }
    }

    var symbol: String {
        switch self {
        case .photo: "photo"
        case .place: "mappin.and.ellipse"
        case .booking: "ticket"
        case .poll: "chart.bar"
        case .meetup: "calendar"
        case .checklist: "checklist"
        case .balances: "arrow.left.arrow.right"
        case .unsupported: "questionmark.square.dashed"
        }
    }

    var previewLabel: String {
        switch self {
        case .photo: "Photo"
        case .place(let place): place.name
        case .booking: "Booking"
        case .poll(let poll): poll.question
        case .meetup(let meetup): meetup.title
        case .checklist(let list): list.title
        case .balances: "Who owes whom"
        case .unsupported: "New kind of message"
        }
    }
}

// MARK: - Wire

/// `messages.payload`, flat and all-optional.
///
/// Flat rather than one Codable enum with associated values: a jsonb column
/// read by three builds of the app has to survive fields it doesn't know and
/// fields it expects going missing, and a flat optional struct does both
/// without a hand-written decoder. `ChatAttachment.init(kind:payload:)` is
/// where a payload is checked for being complete enough to draw.
nonisolated struct ChatPayload: Codable, Equatable {
    var url: String?
    var width: Double?
    var height: Double?
    var name: String?
    var subtitle: String?
    var lat: Double?
    var lon: Double?
    var item_id: String?
    var question: String?
    var options: [ChatAttachment.Option]?
    var multi: Bool?
    var title: String?
    /// ISO 8601, as text — a `Date` inside jsonb comes back in whichever
    /// format the encoder of the day chose, and this has to parse on every
    /// build that reads it.
    var at: String?
    var place: String?
    var items: [ChatAttachment.Option]?
}

extension ChatAttachment {
    /// Reads a stored row. Nil for plain text; `.unsupported` for anything
    /// that doesn't hold together, so a malformed card is visible rather than
    /// silently missing from the thread.
    init?(kind: String, payload: ChatPayload?) {
        let payload = payload ?? ChatPayload()

        switch kind {
        case "text":
            return nil

        case "photo":
            guard let raw = payload.url, let url = URL(string: raw) else { self = .unsupported(kind: kind); return }
            self = .photo(Photo(url: url, width: payload.width ?? 0, height: payload.height ?? 0))

        case "place":
            guard let name = payload.name, let lat = payload.lat, let lon = payload.lon else {
                self = .unsupported(kind: kind); return
            }
            self = .place(Place(name: name, subtitle: payload.subtitle ?? "", latitude: lat, longitude: lon))

        case "booking":
            guard let raw = payload.item_id, let id = UUID(uuidString: raw) else { self = .unsupported(kind: kind); return }
            self = .booking(itemID: id)

        case "poll":
            guard let question = payload.question, let options = payload.options, options.count >= 2 else {
                self = .unsupported(kind: kind); return
            }
            self = .poll(Poll(question: question, options: options, allowsMultiple: payload.multi ?? false))

        case "meetup":
            guard let title = payload.title, let raw = payload.at, let date = Self.parse(raw) else {
                self = .unsupported(kind: kind); return
            }
            self = .meetup(Meetup(title: title, date: date, place: payload.place))

        case "checklist":
            guard let title = payload.title, let items = payload.items, !items.isEmpty else {
                self = .unsupported(kind: kind); return
            }
            self = .checklist(Checklist(title: title, items: items))

        case "balances":
            self = .balances

        default:
            self = .unsupported(kind: kind)
        }
    }

    var payload: ChatPayload {
        var payload = ChatPayload()
        switch self {
        case .photo(let photo):
            payload.url = photo.url.absoluteString
            payload.width = photo.width
            payload.height = photo.height
        case .place(let place):
            payload.name = place.name
            payload.subtitle = place.subtitle
            payload.lat = place.latitude
            payload.lon = place.longitude
        case .booking(let itemID):
            payload.item_id = itemID.uuidString
        case .poll(let poll):
            payload.question = poll.question
            payload.options = poll.options
            payload.multi = poll.allowsMultiple
        case .meetup(let meetup):
            payload.title = meetup.title
            payload.at = ISO8601DateFormatter.supabase.string(from: meetup.date)
            payload.place = meetup.place
        case .checklist(let list):
            payload.title = list.title
            payload.items = list.items
        case .balances, .unsupported:
            break
        }
        return payload
    }

    private static func parse(_ raw: String) -> Date? {
        ISO8601DateFormatter.supabase.date(from: raw) ?? ISO8601DateFormatter.supabaseFractional.date(from: raw)
    }
}
