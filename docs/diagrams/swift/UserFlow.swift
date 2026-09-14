//
//  UserFlow.swift
//  Equitrip — presentation diagram (vertical)
//

import SwiftUI

// MARK: - Connectors

struct Poly: Shape {
    var pts: [CGPoint]
    var r: CGFloat = 7

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard pts.count > 1 else { return p }
        p.move(to: pts[0])
        for i in 1..<pts.count - 1 {
            let a = pts[i - 1], b = pts[i], c = pts[i + 1]
            let d1 = hypot(b.x - a.x, b.y - a.y), d2 = hypot(c.x - b.x, c.y - b.y)
            let t1 = min(r, d1 / 2), t2 = min(r, d2 / 2)
            let p1 = CGPoint(x: b.x + (a.x - b.x) / d1 * t1, y: b.y + (a.y - b.y) / d1 * t1)
            let p2 = CGPoint(x: b.x + (c.x - b.x) / d2 * t2, y: b.y + (c.y - b.y) / d2 * t2)
            p.addLine(to: p1)
            p.addQuadCurve(to: p2, control: b)
        }
        p.addLine(to: pts[pts.count - 1])
        return p
    }
}

struct Head: Shape {
    var pts: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard pts.count >= 2 else { return p }
        let b = pts[pts.count - 1], a = pts[pts.count - 2]
        let len = max(hypot(b.x - a.x, b.y - a.y), 0.001)
        let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
        let px = -uy, py = ux
        let back: CGFloat = 7, half: CGFloat = 3.8
        p.move(to: b)
        p.addLine(to: CGPoint(x: b.x - ux * back + px * half, y: b.y - uy * back + py * half))
        p.addLine(to: CGPoint(x: b.x - ux * back - px * half, y: b.y - uy * back - py * half))
        p.closeSubpath()
        return p
    }
}

struct Edge: View {
    let pts: [CGPoint]
    var tint: Color = AppTheme.inkSecondary.opacity(0.62)
    var head: Bool = true

    var body: some View {
        ZStack {
            Poly(pts: pts).stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            if head { Head(pts: pts).fill(tint) }
        }
    }
}

// MARK: - Cells

struct UFChip: View {
    let label: String
    let mark: BrandMark
    var side: CGFloat = 20

    var body: some View {
        HStack(spacing: 6) {
            BrandTile(mark: mark, side: side)
            Text(label)
                .font(.system(size: side >= 20 ? 11.5 : 10.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize()
        }
        .padding(.leading, 4)
        .padding(.trailing, 9)
        .padding(.vertical, 3)
        .background(AppTheme.card, in: .capsule)
        .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.14)) }
    }
}

struct UFIcon: View {
    let symbol: String
    let tint: Color
    var side: CGFloat = 34

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: side * 0.46, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: side, height: side)
            .background(tint.opacity(0.13), in: .rect(cornerRadius: side * 0.30, style: .continuous))
    }
}

struct UFCard: View {
    let symbol: String
    let title: String
    let detail: String
    let tint: Color
    var chip: (String, BrandMark)? = nil
    var size: CGSize
    var titleSize: CGFloat = 15
    var detailSize: CGFloat = 11.5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                UFIcon(symbol: symbol, tint: tint, side: 32)
                Text(title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(detail)
                .font(.system(size: detailSize))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Spacer(minLength: 0)

            if let chip { UFChip(label: chip.0, mark: chip.1) }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(AppTheme.card, in: .rect(cornerRadius: 17, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(AppTheme.cardStroke.opacity(0.13)) }
    }
}

struct UFPill: View {
    let symbol: String
    let title: String
    let detail: String
    let tint: Color
    var size: CGSize

    var body: some View {
        HStack(spacing: 10) {
            UFIcon(symbol: symbol, tint: tint, side: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(width: size.width, height: size.height, alignment: .leading)
        .background(AppTheme.card, in: .rect(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.cardStroke.opacity(0.13)) }
    }
}

struct UFDecision: View {
    let title: String
    var size: CGSize

    var body: some View {
        ZStack {
            Diamond()
                .fill(AppTheme.card)
                .overlay { Diamond().stroke(Palette.amber, lineWidth: 1.6) }
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
        }
        .frame(width: size.width, height: size.height)
    }
}

struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

struct UFStage: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.7)
            .foregroundStyle(AppTheme.inkTertiary)
    }
}

// MARK: - Diagram

struct EquitripUserFlow: View {
    private let W: CGFloat = 700
    private let H: CGFloat = 900

    private let colL: CGFloat = 24
    private let colR: CGFloat = 362
    private let wide = CGSize(width: 314, height: 112)
    private let third = CGSize(width: 204, height: 58)

    private func at(_ v: some View, _ x: CGFloat, _ y: CGFloat) -> some View {
        v.position(x: x, y: y)
    }

    private func stage(_ t: String, _ y: CGFloat) -> some View {
        UFStage(title: t)
            .frame(width: 320, alignment: .leading)
            .position(x: 24 + 160, y: y)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            Group {
                Edge(pts: [.init(x: 126, y: 90), .init(x: 126, y: 98),
                           .init(x: 160, y: 98), .init(x: 160, y: 116)])
                Edge(pts: [.init(x: 126, y: 98), .init(x: 519, y: 98),
                           .init(x: 519, y: 116)])
                Edge(pts: [.init(x: 574, y: 90), .init(x: 574, y: 110),
                           .init(x: 12, y: 110), .init(x: 12, y: 566),
                           .init(x: 20, y: 566)])
                Edge(pts: [.init(x: 350, y: 90), .init(x: 350, y: 352),
                           .init(x: 341, y: 352)])

                Edge(pts: [.init(x: 160, y: 234), .init(x: 160, y: 260)])
                Edge(pts: [.init(x: 519, y: 234), .init(x: 519, y: 248),
                           .init(x: 210, y: 248), .init(x: 210, y: 260)])

                Edge(pts: [.init(x: 181, y: 376), .init(x: 181, y: 384)])
                Edge(pts: [.init(x: 273, y: 422), .init(x: 358, y: 422)])
                Edge(pts: [.init(x: 181, y: 458), .init(x: 181, y: 506)])
                Edge(pts: [.init(x: 519, y: 480), .init(x: 519, y: 494),
                           .init(x: 260, y: 494), .init(x: 260, y: 506)])

                Edge(pts: [.init(x: 340, y: 566), .init(x: 358, y: 566)])
                Edge(pts: [.init(x: 519, y: 624), .init(x: 519, y: 640),
                           .init(x: 350, y: 640), .init(x: 350, y: 650)])
            }

            Group {
                Edge(pts: [.init(x: 350, y: 750), .init(x: 350, y: 766),
                           .init(x: 126, y: 766), .init(x: 126, y: 776)])
                Edge(pts: [.init(x: 350, y: 766), .init(x: 350, y: 776)])
                Edge(pts: [.init(x: 350, y: 766), .init(x: 574, y: 766),
                           .init(x: 574, y: 776)])
            }

            at(Text("Yes")
                .font(.system(size: 10.5, weight: .heavy))
                .foregroundStyle(Palette.amber), 312, 412)
            at(Text("No")
                .font(.system(size: 10.5, weight: .heavy))
                .foregroundStyle(Palette.green), 199, 486)

            // 1 — entry points
            stage("ENTRY POINTS", 14)
            at(UFPill(symbol: "tray.and.arrow.down.fill", title: "Automatic import",
                      detail: "Gmail, ticket PDFs and photos",
                      tint: AppTheme.accent, size: third), colL + 102, 59)
            at(UFPill(symbol: "square.and.pencil", title: "Manual entry",
                      detail: "Days, bookings and costs",
                      tint: Palette.stone, size: third), 248 + 102, 59)
            at(UFPill(symbol: "qrcode.viewfinder", title: "Invite code",
                      detail: "Scan or enter the trip code",
                      tint: Palette.green, size: third), 472 + 102, 59)

            // 2 — data sources
            stage("DATA SOURCES", 106)
            at(UFCard(symbol: "envelope.fill", title: "Gmail",
                      detail: "Confirmations and receipts, read-only.",
                      tint: AppTheme.danger, chip: ("Gmail API", .gmail), size: wide),
               colL + 157, 176)
            at(UFCard(symbol: "doc.text.fill", title: "Documents",
                      detail: "Ticket PDFs, boarding passes, bills.",
                      tint: Palette.blue,
                      chip: ("PDFKit · Vision", .asset("vision.png", needsTile: false)), size: wide),
               colR + 157, 176)

            // 3 — on-device processing
            stage("ON-DEVICE PROCESSING", 250)
            at(UFCard(symbol: "doc.viewfinder.fill", title: "Document analysis",
                      detail: "Vendor, amount, date, travellers, category.",
                      tint: AppTheme.accent,
                      chip: ("Foundation Models", .asset("Foundation.png", needsTile: false)),
                      size: wide),
               colL + 157, 320)
            at(UFDecision(title: "Conflicts or\nduplicates?",
                          size: CGSize(width: 184, height: 72)), 181, 422)
            at(UFCard(symbol: "checkmark.seal.fill", title: "Validation",
                      detail: "Merges duplicates, completes missing fields.",
                      tint: Palette.amber,
                      chip: ("Foundation Models", .asset("Foundation.png", needsTile: false)),
                      size: wide),
               colR + 157, 422)

            // 4 — trip record
            stage("TRIP RECORD", 496)
            at(UFCard(symbol: "suitcase.fill", title: "Trip created",
                      detail: "Itinerary, bookings and participants stored.",
                      tint: AppTheme.accent,
                      chip: ("Supabase", .asset("supabase.png", needsTile: false)), size: wide),
               colL + 157, 566)
            at(UFCard(symbol: "creditcard.fill", title: "Expense ledger",
                      detail: "Costs attributed under the split rule in force.",
                      tint: Palette.green, size: wide),
               colR + 157, 566)

            // 5 — settlement
            stage("SETTLEMENT", 640)
            at(UFCard(symbol: "arrow.left.arrow.right", title: "Settlement engine",
                      detail: "Nets every balance across the trip and computes the minimum set of transfers that clears it. Re-runs on every ledger change.",
                      tint: Palette.indigo,
                      size: CGSize(width: 652, height: 94), titleSize: 15.5, detailSize: 12),
               350, 701)

            // 6 — output
            stage("OUTPUT", 766)
            outCard("square.grid.2x2.fill", "Trip dashboard", "Plan, spend and balances",
                    Palette.blue, ("SwiftUI · MapKit", .asset("mapkit.png", needsTile: false)), 0)
            outCard("person.crop.circle.fill", "Personal view", "Your share, owed and owing",
                    Palette.violet, ("SwiftUI", .asset("Swifti.png", needsTile: false)), 1)
            outCard("doc.richtext.fill", "Statements", "Per-traveller PDF export",
                    Palette.green, ("PDFKit · Swift", .asset("swift.png", needsTile: false)), 2)
        }
        .frame(width: W, height: H, alignment: .topLeading)
    }

    @ViewBuilder
    private func outCard(_ symbol: String, _ title: String, _ detail: String,
                         _ tint: Color, _ chip: (String, BrandMark), _ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                UFIcon(symbol: symbol, tint: tint, side: 26)
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(detail)
                .font(.system(size: 10.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 6)
            Spacer(minLength: 0)
            UFChip(label: chip.0, mark: chip.1, side: 18)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 11)
        .frame(width: 204, height: 100, alignment: .topLeading)
        .background(AppTheme.card, in: .rect(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.cardStroke.opacity(0.13)) }
        .position(x: 24 + CGFloat(i) * 224 + 102, y: 826)
    }
}
