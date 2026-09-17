//
//  ChatCards.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// The component inside a message, drawn as the thing it is.
///
/// Cards are white whoever sent them. A poll or a booking on the accent
/// gradient would need a second, inverted design for every control inside
/// it; which side of the thread the card sits on already says whose it is.
struct ChatAttachmentCard: View {
    let message: ChatMessage
    let attachment: ChatAttachment
    let trip: Trip
    let chat: ChatService
    var onOpenBooking: (ItineraryItem) -> Void
    var onOpenPhoto: (URL) -> Void

    static let width: CGFloat = 268

    var body: some View {
        switch attachment {
        case .photo(let photo):
            ChatPhotoCard(
                photo: photo,
                local: chat.localImages[message.id],
                isSending: message.delivery == .sending,
                onOpen: { onOpenPhoto(photo.url) }
            )

        case .place(let place):
            ChatPlaceCard(place: place)

        case .booking(let itemID):
            ChatBookingCard(item: trip.items.first { $0.id == itemID }, trip: trip, onOpen: onOpenBooking)

        case .poll(let poll):
            ChatPollCard(message: message, poll: poll, trip: trip, chat: chat)

        case .meetup(let meetup):
            ChatMeetupCard(message: message, meetup: meetup, chat: chat)

        case .checklist(let list):
            ChatChecklistCard(message: message, list: list, chat: chat)

        case .balances:
            ChatBalancesCard(trip: trip)

        case .unsupported:
            ChatCardFrame {
                HStack(spacing: 10) {
                    SymbolBadge(symbol: "sparkles", tint: AppTheme.accent, size: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Something new")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("Update Equitrip to see this message.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                }
                .padding(14)
            }
        }
    }
}

// MARK: - Frame

/// The white card every component sits in.
struct ChatCardFrame<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(width: ChatAttachmentCard.width, alignment: .leading)
            .cardSurface(corner: 20, shadow: 5)
    }
}

/// The small label at the top of a card: what kind of thing this is.
struct ChatCardEyebrow: View {
    let symbol: String
    let title: String
    var tint: Color = AppTheme.accent
    var trailing: String?

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.6)
            Spacer(minLength: 4)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
        .foregroundStyle(tint)
    }
}

// MARK: - Photo

struct ChatPhotoCard: View {
    let photo: ChatAttachment.Photo
    /// The picked image, while it's still uploading.
    let local: UIImage?
    let isSending: Bool
    var onOpen: () -> Void

    private static let width: CGFloat = 240

    var body: some View {
        Button(action: onOpen) {
            image
                .frame(width: Self.width, height: Self.width / photo.aspectRatio)
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                }
                .overlay {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: .circle)
                            .environment(\.colorScheme, .dark)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(local != nil)
        .accessibilityLabel("Photo")
    }

    @ViewBuilder
    private var image: some View {
        if let local {
            Image(uiImage: local).resizable().scaledToFill()
        } else {
            ChatRemoteImage(url: photo.url)
        }
    }
}

// MARK: - Place

struct ChatPlaceCard: View {
    let place: ChatAttachment.Place

    var body: some View {
        Button(action: openInMaps) {
            ChatCardFrame {
                VStack(alignment: .leading, spacing: 0) {
                    ChatMapSnapshot(latitude: place.latitude, longitude: place.longitude)
                        .frame(width: ChatAttachmentCard.width, height: 132)
                        .clipShape(UnevenRoundedRectangle(
                            cornerRadii: .init(topLeading: 20, bottomLeading: 0, bottomTrailing: 0, topTrailing: 20),
                            style: .continuous
                        ))

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(place.name)
                                .font(.system(size: 14.5, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                            if !place.subtitle.isEmpty {
                                Text(place.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.inkSecondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                }
                .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Place: \(place.name). Opens in Maps.")
    }

    private func openInMaps() {
        let item = MKMapItem(
            location: CLLocation(latitude: place.latitude, longitude: place.longitude),
            address: nil
        )
        item.name = place.name
        item.openInMaps()
    }
}

/// A still of the map around a point, with a pin drawn over its centre.
///
/// A snapshot rather than a live `Map`: a thread can hold a dozen places, and
/// a dozen live map views scrolling in a lazy stack is a dozen renderers
/// spinning up and tearing down. The still is made once and cached for the
/// life of the process.
struct ChatMapSnapshot: View {
    let latitude: Double
    let longitude: Double

    @State private var image: UIImage?

    private static var cache: [String: UIImage] = [:]

    private var key: String { String(format: "%.5f,%.5f", latitude, longitude) }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Rectangle().fill(Palette.blue.opacity(0.08))
            }

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, AppTheme.danger)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .offset(y: -10)
        }
        .task(id: key) { await render() }
    }

    private func render() async {
        if let cached = Self.cache[key] {
            image = cached
            return
        }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            latitudinalMeters: 1200,
            longitudinalMeters: 1200
        )
        options.size = CGSize(width: ChatAttachmentCard.width, height: 132)
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)

        guard let snapshot = try? await MKMapSnapshotter(options: options).start() else { return }
        Self.cache[key] = snapshot.image
        withAnimation(.easeOut(duration: 0.25)) { image = snapshot.image }
    }
}

// MARK: - Booking

/// A booking shared into the thread, read from the trip every time it's drawn.
struct ChatBookingCard: View {
    let item: ItineraryItem?
    let trip: Trip
    var onOpen: (ItineraryItem) -> Void

    var body: some View {
        if let item {
            Button { onOpen(item) } label: { card(for: item) }
                .buttonStyle(PressableButtonStyle())
        } else {
            // Deleted since it was shared. Said plainly, so a reply like "is
            // this still on?" has an answer in the card itself.
            ChatCardFrame {
                HStack(spacing: 10) {
                    SymbolBadge(symbol: "ticket", tint: AppTheme.inkTertiary, size: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Booking removed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("It's no longer on the itinerary.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                }
                .padding(14)
            }
        }
    }

    private func card(for item: ItineraryItem) -> some View {
        let payer = item.paidByID.flatMap(trip.traveller)
        let yourShare = trip.share(of: item, for: Traveller.you.id)

        return ChatCardFrame {
            VStack(alignment: .leading, spacing: 11) {
                ChatCardEyebrow(symbol: item.kind.symbol, title: item.kind.label, tint: item.kind.tint, trailing: whenLabel(item))

                HStack(spacing: 11) {
                    IconTile(symbol: item.symbol, tint: item.kind.tint, size: 38)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(2)
                        if let vendor = item.vendorName {
                            Text(vendor)
                                .font(.system(size: 12.5))
                                .foregroundStyle(AppTheme.inkSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                if item.cost > 0 {
                    Hairline()

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(Money.format(item.cost, code: trip.currencyCode))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                            Text(payer.map { "Paid by \($0.id == Traveller.you.id ? "you" : $0.name)" } ?? "Not paid yet")
                                .font(.system(size: 11.5))
                                .foregroundStyle(payer == nil ? Palette.amber : AppTheme.inkTertiary)
                        }

                        Spacer(minLength: 6)

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(yourShare > 0 ? Money.format(yourShare, code: trip.currencyCode) : "—")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                            Text("your share")
                                .font(.system(size: 11.5))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }
                    }
                }
            }
            .padding(14)
            .multilineTextAlignment(.leading)
        }
    }

    private func whenLabel(_ item: ItineraryItem) -> String {
        let day = DateFormatter.cached("EEE d MMM").string(from: item.date)
        return item.timeLabel.map { "\(day) · \($0)" } ?? day
    }
}

// MARK: - Balances

/// Who owes whom, as of the moment you're looking at it.
///
/// Live on purpose. "Here's where we stand" posted on Tuesday and read on
/// Thursday would otherwise tell people to pay amounts that have since been
/// settled — so the card is the question, and the ledger answers it each time.
struct ChatBalancesCard: View {
    let trip: Trip

    var body: some View {
        ChatCardFrame {
            VStack(alignment: .leading, spacing: 11) {
                ChatCardEyebrow(symbol: "arrow.left.arrow.right", title: "Who owes whom", trailing: "Live")

                if !trip.showsBalance {
                    Text("Nothing's been paid for yet. Balances start once somebody records a payment.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if transfers.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AppTheme.positive)
                        Text(trip.pendingSettlements.isEmpty ? "Everyone's square." : "Square once pending payments are confirmed.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(transfers.prefix(5)) { transfer in
                            row(transfer)
                        }
                    }

                    if transfers.count > 5 {
                        Text("+ \(transfers.count - 5) more on the Settle tab")
                            .font(.system(size: 11.5))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }

                if trip.showsBalance {
                    Hairline()
                    HStack {
                        Text("You")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(AppTheme.inkSecondary)
                        Spacer()
                        Text(yourLabel)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(yourTone)
                    }
                }
            }
            .padding(14)
        }
    }

    private var transfers: [SettlementEngine.Transfer] { trip.suggestedTransfers }

    private var yourBalance: Double { trip.remainingBalance(for: Traveller.you.id) }

    private var yourLabel: String {
        if abs(yourBalance) < SettlementEngine.epsilon { return "All square" }
        let amount = Money.format(abs(yourBalance), code: trip.currencyCode)
        return yourBalance > 0 ? "get back \(amount)" : "owe \(amount)"
    }

    private var yourTone: Color {
        if abs(yourBalance) < SettlementEngine.epsilon { return AppTheme.moneyFlat }
        return yourBalance > 0 ? AppTheme.moneyIn : AppTheme.moneyOut
    }

    private func row(_ transfer: SettlementEngine.Transfer) -> some View {
        let from = trip.traveller(transfer.from)
        let to = trip.traveller(transfer.to)
        let involvesYou = transfer.from == Traveller.you.id || transfer.to == Traveller.you.id

        return HStack(spacing: 5) {
            if let from { TravellerAvatar(traveller: from, size: 20) }
            Text(name(from))
                .font(.system(size: 13, weight: involvesYou ? .semibold : .regular))
                .lineLimit(1)
            Image(systemName: "arrow.right")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(AppTheme.inkTertiary)
            if let to { TravellerAvatar(traveller: to, size: 20) }
            Text(name(to))
                .font(.system(size: 13, weight: involvesYou ? .semibold : .regular))
                .lineLimit(1)
            Spacer(minLength: 4)
            // The figure never wraps — a name truncates first. "₹31,913.2"
            // over a lone "5" reads as a different amount. Priority, not
            // `.fixedSize()`: a fixed-size figure beside truncating names never
            // settled on a width inside the thread's lazy stack, which re-laid
            // the whole thread forever and froze the app at 100% CPU.
            Text(Money.format(transfer.amount, code: trip.currencyCode))
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .layoutPriority(1)
                .foregroundStyle(transfer.from == Traveller.you.id ? AppTheme.moneyOut : (transfer.to == Traveller.you.id ? AppTheme.moneyIn : AppTheme.ink))
        }
        .foregroundStyle(AppTheme.ink)
    }

    private func name(_ person: Traveller?) -> String {
        guard let person else { return "Someone" }
        return person.id == Traveller.you.id ? "You" : person.name
    }
}
