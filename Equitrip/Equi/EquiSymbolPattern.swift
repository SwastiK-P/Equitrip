//
//  EquiSymbolPattern.swift
//  Equitrip
//

import SwiftUI

/// A faint wallpaper of travel and money glyphs behind Equi.
///
/// The aurora on its own is a colour, not a place — a violet haze that could
/// sit behind any assistant in any app. Tiling the things Equi actually knows
/// about (flights, bags, rupees, receipts, the ledger's arrows) says what this
/// assistant is *for* before anybody has typed a word, the way a chat app's
/// doodle wallpaper does.
///
/// Drawn in one `Canvas` from symbols resolved once, rather than as a few
/// hundred `Image` views: it covers the whole screen and sits under a mesh
/// that animates, so it has to cost one layer, not one per glyph. The layout
/// is deterministic — a staggered grid with a fixed rotation per cell — so it
/// never reshuffles when the view redraws.
struct EquiSymbolPattern: View {
    private static let symbols = [
        "airplane", "suitcase.rolling", "indianrupeesign", "map",
        "creditcard", "tram", "receipt", "globe.asia.australia",
        "arrow.left.arrow.right", "camera", "banknote", "mappin.and.ellipse",
        "ticket", "fork.knife", "chart.pie", "beach.umbrella",
        "calendar", "bag", "building.2", "sun.max",
        "car", "list.bullet.clipboard", "mountain.2", "person.2"
    ]

    /// Wide enough that the glyphs read as a texture rather than a grid of
    /// icons to be tapped.
    private let cell: CGFloat = 62

    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / cell) + 2
            let rows = Int(size.height / cell) + 2

            for row in 0..<rows {
                // Every other row shifted half a cell, so no two glyphs stack
                // into an obvious column.
                let shift = row.isMultiple(of: 2) ? 0 : cell / 2

                for column in 0..<columns {
                    let index = (row * 7 + column * 5) % Self.symbols.count
                    guard let symbol = context.resolveSymbol(id: index) else { continue }

                    // A fixed, per-cell tilt between −18° and +18°: enough to
                    // feel hand-scattered, never enough to look like it moved.
                    let tilt = Double(((row * 31 + column * 17) % 37) - 18)

                    context.drawLayer { layer in
                        layer.translateBy(x: CGFloat(column) * cell + shift, y: CGFloat(row) * cell + cell / 2)
                        layer.rotate(by: .degrees(tilt))
                        layer.draw(symbol, at: .zero, anchor: .center)
                    }
                }
            }
        } symbols: {
            ForEach(Self.symbols.indices, id: \.self) { index in
                Image(systemName: Self.symbols[index])
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.accentDeep)
                    .tag(index)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
