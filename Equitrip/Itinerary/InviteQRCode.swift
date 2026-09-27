//
//  InviteQRCode.swift
//  Equitrip
//

import SwiftUI

/// The invite's QR drawn module by module, with the app icon in the middle.
///
/// Drawn rather than shown as Core Image's bitmap so the modules can be rounded
/// and the three finder patterns rounded "eyes". What a scanner needs survives
/// this: the eyes keep their 7‑3 ring-and-pupil proportions, every module stays
/// dark on white, and the icon only covers modules that error correction level
/// H (30% recoverable) can rebuild — the hole is kept to about 5% of the code.
struct InviteQRCode: View {
    /// Modules and eye rings. Near-black navy rather than pure black, dark enough
    /// that contrast against white is effectively unchanged.
    static let moduleInk = Color(red: 0.11, green: 0.10, blue: 0.23)
    /// The eyes' pupils, in the brand indigo. Fixed rather than
    /// `AppTheme.accent`, whose dark-mode value is too light to scan on white.
    static let pupilInk = Color(red: 0.29, green: 0.27, blue: 0.78)

    private let modules: [[Bool]]

    init(payload: String) {
        modules = QRCode.matrix(from: payload, correction: "H")
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let count = max(modules.count, 1)
            let cell = side / CGFloat(count)
            let hole = holeSpan(count: count)

            ZStack {
                if modules.isEmpty {
                    Image(systemName: "qrcode")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.black.opacity(0.25))
                } else {
                    Canvas { context, _ in
                        drawModules(in: &context, cell: cell, hole: hole)
                        for origin in eyeOrigins(count: count) {
                            drawEye(in: &context, at: origin, cell: cell)
                        }
                    }

                    logo(side: CGFloat(hole.count) * cell)
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Drawing

    private func drawModules(in context: inout GraphicsContext, cell: CGFloat, hole: ClosedRange<Int>) {
        let count = modules.count
        // Full-cell modules with soft corners. Gapped dots looked lighter but
        // failed to decode at small sizes that a plain code survives.
        let corner = cell * 0.3
        var path = Path()

        for row in 0..<count {
            for column in 0..<count where modules[row][column] {
                if isEye(row: row, column: column, count: count) { continue }
                if hole.contains(row), hole.contains(column) { continue }
                path.addRoundedRect(
                    in: CGRect(
                        x: CGFloat(column) * cell,
                        y: CGFloat(row) * cell,
                        width: cell,
                        height: cell
                    ),
                    cornerSize: CGSize(width: corner, height: corner),
                    style: .continuous
                )
            }
        }

        context.fill(path, with: .color(Self.moduleInk))
    }

    /// A finder pattern: a 7-module ring around a 3-module pupil, softened.
    private func drawEye(in context: inout GraphicsContext, at origin: (row: Int, column: Int), cell: CGFloat) {
        let outer = CGRect(
            x: CGFloat(origin.column) * cell,
            y: CGFloat(origin.row) * cell,
            width: cell * 7,
            height: cell * 7
        )
        var ring = Path(roundedRect: outer, cornerRadius: cell * 2.2, style: .continuous)
        ring.addPath(Path(roundedRect: outer.insetBy(dx: cell, dy: cell), cornerRadius: cell * 1.5, style: .continuous))
        context.fill(ring, with: .color(Self.moduleInk), style: FillStyle(eoFill: true))

        let pupil = Path(roundedRect: outer.insetBy(dx: cell * 2, dy: cell * 2), cornerRadius: cell * 1.1, style: .continuous)
        context.fill(pupil, with: .color(Self.pupilInk))
    }

    private func logo(side: CGFloat) -> some View {
        let tile = side - 4
        return Image("AppMark")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: tile * 0.84, height: tile * 0.84)
            .frame(width: tile, height: tile)
            .background(.white, in: .rect(cornerRadius: tile * 0.26, style: .continuous))
            .accessibilityHidden(true)
    }

    // MARK: Geometry

    private func eyeOrigins(count: Int) -> [(row: Int, column: Int)] {
        [(0, 0), (0, count - 7), (count - 7, 0)]
    }

    private func isEye(row: Int, column: Int, count: Int) -> Bool {
        eyeOrigins(count: count).contains { origin in
            (origin.row..<origin.row + 7).contains(row) && (origin.column..<origin.column + 7).contains(column)
        }
    }

    /// The centred run of rows (and columns) cleared for the icon: about a
    /// fifth of the code's width, odd so it sits exactly on the centre module.
    private func holeSpan(count: Int) -> ClosedRange<Int> {
        var span = Int((Double(count) * 0.25).rounded())
        if span % 2 == 0 { span += 1 }
        let start = (count - span) / 2
        return start...(start + span - 1)
    }
}

#Preview {
    InviteQRCode(payload: "https://equitrip.app/join/TX9-VRF")
        .padding(20)
        .background(.white)
        .frame(width: 268)
}
