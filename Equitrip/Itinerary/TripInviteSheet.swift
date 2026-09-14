//
//  TripInviteSheet.swift
//  Equitrip
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Inviting someone to a trip.
///
/// The card used to tilt with the phone — a parallax pass driven by
/// `CMDeviceMotion`. It read well in a screenshot and badly in the hand: the
/// one thing on this screen that has to hold still is the QR, because someone
/// across the table is pointing a camera at it, and a code that drifts and
/// catches a specular band is a code their scanner keeps losing lock on. So
/// the card is fixed now, and everything the motion was buying — depth, a
/// sense of an object rather than a panel — comes from the shape instead: a
/// torn ticket with the trip's photograph as its head and the code as its
/// stub.
///
/// The QR is the largest thing on the screen by a wide margin. It's what the
/// screen is *for*; the code underneath is the fallback for when there's no
/// camera pointed at it, not the other way round.
struct TripInviteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var copied = false
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                InviteTicket(trip: trip)
                    .padding(.top, 4)
                    .scaleEffect(appeared ? 1 : 0.94)
                    .opacity(appeared ? 1 : 0)

                actions
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                footnote
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { appeared = true }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Invite to trip")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("Anyone with this code joins \(trip.title)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Actions

    /// Two peers, side by side. Copying and sharing are the same size of
    /// decision — one goes into a message you're already writing, the other
    /// opens the share sheet — so neither gets to be the primary.
    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: copy) {
                actionLabel(
                    symbol: copied ? "checkmark" : "doc.on.doc",
                    title: copied ? "Copied" : "Copy code"
                )
            }
            .buttonStyle(.glass)
            .tint(copied ? AppTheme.positive : AppTheme.accent)

            if let link = trip.inviteLink {
                ShareLink(item: link, message: Text("Join \(trip.title) on Equitrip")) {
                    actionLabel(symbol: "square.and.arrow.up", title: "Share")
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: copied)
    }

    private func actionLabel(symbol: String, title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
            Text(title)
                .font(.system(size: 15.5, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
    }

    private func copy() {
        UIPasteboard.general.string = trip.inviteCode
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        copied = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    private var footnote: some View {
        Text("They'll be added as a traveller. Nothing is charged to them until they're put on a booking.")
            .font(.system(size: 12))
            .foregroundStyle(AppTheme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.top, 2)
    }
}

// MARK: - Ticket

/// The invite, as a torn ticket: the trip's photograph on the head, the code
/// on the stub, and the QR filling everything in between.
private struct InviteTicket: View {
    @Environment(\.colorScheme) private var scheme
    let trip: Trip

    /// Where the tear sits, measured from the top. Shared by the shape and
    /// the layout so the notches land exactly on the perforation.
    private let headHeight: CGFloat = 152
    private let corner: CGFloat = 28

    private var qr: UIImage? {
        QRCode.make(from: trip.inviteLink?.absoluteString ?? trip.inviteCode)
    }

    var body: some View {
        VStack(spacing: 0) {
            head
            perforation
            body_
        }
        .background(AppTheme.card, in: TicketShape(corner: corner, headHeight: headHeight))
        // Clipped to the ticket, not just backed by it.
        //
        // The notch is centred on the tear, so half of each bite falls inside
        // the photograph — and the photograph is its own view drawn on top of
        // the background, so it filled the top half back in. The card read as
        // torn along the bottom edge of the perforation and solid along the
        // top, which is not how paper tears. Clipping the whole card to the
        // same shape takes the bite out of the image too.
        .clipShape(TicketShape(corner: corner, headHeight: headHeight))
        .overlay {
            TicketShape(corner: corner, headHeight: headHeight)
                .stroke(AppTheme.cardStroke.opacity(scheme == .dark ? 0.10 : 0.05), lineWidth: 1)
        }
        .shadow(color: AppTheme.softShadow(scheme), radius: 20, y: 10)
    }

    // MARK: Head

    private var head: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint
        )
        .frame(height: headHeight)
        .frame(maxWidth: .infinity)
        .overlay {
            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .bottomLeading) {
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.title)
                        .font(AppTheme.display(21))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("\(trip.dateRange) · \(trip.travellers.count.pluralised("traveller"))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                AvatarStack(travellers: trip.travellers, size: 24, max: 4, departedIDs: trip.departedIDs)
            }
            .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
            .padding(.horizontal, 16)
            .padding(.bottom, 13)
        }
        // Clipped to the ticket's own head so the photograph takes the card's
        // top corners and stops dead on the perforation.
        .clipShape(.rect(topLeadingRadius: corner, topTrailingRadius: corner, style: .continuous))
    }

    private var perforation: some View {
        DashedLine()
            .stroke(
                AppTheme.cardStroke.opacity(0.18),
                style: StrokeStyle(lineWidth: 1, dash: [5, 4])
            )
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    // MARK: Body

    /// `body_` rather than `body`, which the protocol has already claimed.
    private var body_: some View {
        VStack(spacing: 18) {
            qrPanel
            codeBlock
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 22)
    }

    /// The QR, as large as the card allows, on white.
    ///
    /// White regardless of appearance, and never tinted: a scanner is looking
    /// for maximum contrast between module and quiet zone, and every clever
    /// thing you can do to a QR — a gradient, a logo, the app's own peach —
    /// spends some of that contrast. The corner brackets sit outside the quiet
    /// zone so they frame it without eating into it.
    private var qrPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white)

            if let qr {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .accessibilityLabel("QR code for join code \(trip.inviteCode)")
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.black.opacity(0.25))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 268)
        .overlay { brackets }
        .shadow(color: AppTheme.softShadow(scheme), radius: 10, y: 5)
    }

    private var brackets: some View {
        GeometryReader { proxy in
            let length = min(proxy.size.width, proxy.size.height) * 0.16

            ZStack {
                ForEach(Corner.allCases, id: \.self) { position in
                    BracketShape(corner: position, length: length, radius: 18)
                        .stroke(trip.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
            .padding(9)
        }
    }

    private var codeBlock: some View {
        VStack(spacing: 6) {
            Text("JOIN CODE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(trip.inviteCode)
                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                .tracking(3)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("Scan the code, or type it in Join a trip")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shapes

/// Which corner a bracket belongs to. Shared by the invite card and the
/// scanner's aperture, so the two screens frame a QR the same way.
enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

/// One corner of a viewfinder frame: two arms meeting at a rounded elbow.
struct BracketShape: Shape {
    var corner: Corner
    var length: CGFloat
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch corner {
        case .topLeading:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius + length))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX + radius + length, y: rect.minY))

        case .topTrailing:
            path.move(to: CGPoint(x: rect.maxX - radius - length, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(270),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius + length))

        case .bottomTrailing:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - length))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX - radius - length, y: rect.maxY))

        case .bottomLeading:
            path.move(to: CGPoint(x: rect.minX + radius + length, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius - length))
        }

        return path
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// A rounded rectangle bitten into on both sides at the tear line.
private struct TicketShape: Shape {
    var corner: CGFloat = 28
    var notchRadius: CGFloat = 11
    /// Distance from the top to the perforation.
    var headHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let notchY = rect.minY + headHeight
        var path = Path(roundedRect: rect, cornerRadius: corner, style: .continuous)

        for centre in [CGPoint(x: rect.minX, y: notchY), CGPoint(x: rect.maxX, y: notchY)] {
            path = path.subtracting(
                Path(ellipseIn: CGRect(
                    x: centre.x - notchRadius,
                    y: centre.y - notchRadius,
                    width: notchRadius * 2,
                    height: notchRadius * 2
                ))
            )
        }

        return path
    }
}

// MARK: - QR

enum QRCode {
    private static let context = CIContext()

    /// The code as a grid of dark/light modules.
    ///
    /// Rendered at one pixel per module and read back, rather than parsed:
    /// Core Image already knows how to lay a QR out, and the alternative is
    /// reimplementing Reed–Solomon to find out where the black squares go.
    /// The scanner's burst animation is the only caller — the particles it
    /// throws are the actual modules of the code that was just scanned, which
    /// is the whole reason the effect reads as the code coming apart rather
    /// than as confetti.
    static func matrix(from string: String) -> [[Bool]] {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return [] }
        let side = Int(output.extent.width.rounded())
        // A payload long enough to need a version-40 code isn't one of ours,
        // and a matrix that big would be thousands of particles.
        guard side > 0, side <= 120, Int(output.extent.height.rounded()) == side else { return [] }

        guard let image = context.createCGImage(output, from: output.extent) else { return [] }

        var pixels = [UInt8](repeating: 0, count: side * side)
        guard let buffer = CGContext(
            data: &pixels,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return [] }

        buffer.interpolationQuality = .none
        buffer.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))

        // Core Graphics draws bottom-up, so the rows come back flipped.
        let grid = (0..<side).map { row in
            (0..<side).map { column in pixels[(side - 1 - row) * side + column] < 128 }
        }

        return trimmed(grid)
    }

    /// Drops the quiet zone.
    ///
    /// Core Image pads its output with a one-module light border. The scanner
    /// reports the bounds of the *symbol*, finder pattern to finder pattern,
    /// so leaving the padding on draws the code a module too big and half a
    /// module off-centre from the thing it's supposed to be sitting on top of.
    private static func trimmed(_ grid: [[Bool]]) -> [[Bool]] {
        guard let first = grid.firstIndex(where: { $0.contains(true) }),
              let last = grid.lastIndex(where: { $0.contains(true) })
        else { return grid }

        let rows = Array(grid[first...last])
        guard let left = rows.compactMap({ $0.firstIndex(of: true) }).min(),
              let right = rows.compactMap({ $0.lastIndex(of: true) }).max()
        else { return rows }

        return rows.map { Array($0[left...right]) }
    }

    static func make(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        // Medium correction survives the rounded frame and a bit of glare
        // without making the modules so dense they blur when scaled up.
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        TripInviteSheet(
            trip: Trip(
                title: "Goa Escape",
                destination: "Goa, India",
                startDate: .daysFromToday(4),
                endDate: .daysFromToday(9),
                travellers: [.ed, .krishna, .kim]
            )
        )
    }
}
