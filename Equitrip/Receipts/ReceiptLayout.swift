//
//  ReceiptLayout.swift
//  Equitrip
//

import CoreGraphics
import Foundation

/// One piece of text on a row, with its horizontal extent.
struct ReceiptCell: Hashable {
    var text: String
    var alternatives: [String]
    var minX: CGFloat
    var maxX: CGFloat
    /// Height of the printed line, the nearest thing to a font size.
    var height: CGFloat
    var isTitle: Bool

    var midX: CGFloat { (minX + maxX) / 2 }
}

/// One visual row of a receipt, left to right.
struct ReceiptRow: Identifiable, Hashable {
    /// Position from the top of the whole receipt, across pages.
    var id: Int
    var page: Int
    var cells: [ReceiptCell]
    /// Normalised to its page, origin top-left.
    var box: CGRect

    var text: String { cells.map(\.text).joined(separator: "  ") }
    var height: CGFloat { cells.map(\.height).max() ?? 0 }
    var isTitle: Bool { cells.contains(where: \.isTitle) }
    var minX: CGFloat { cells.first?.minX ?? box.minX }
}

/// Puts a receipt's scattered lines back into the rows they were printed as.
///
/// Recognition returns lines, not rows, and on a receipt those differ: the
/// wide gap between an item and its price is exactly the kind of gap that
/// splits one printed row into two observations. Sorting those by their top
/// edge interleaves neighbouring rows whenever the paper is even slightly
/// rotated, because the right-hand end of a tilted row sits higher or lower
/// than its left.
///
/// So the tilt is measured first — the median slope of the long lines, which
/// all share the paper's rotation — and every line is projected back to where
/// its row would sit if the paper were straight. Lines whose projections are
/// within half a line-height of each other, and don't overlap sideways, are
/// one row.
enum ReceiptLayout {

    static func rows(from lines: [ReceiptTextLine], page: Int) -> [ReceiptRow] {
        guard !lines.isEmpty else { return [] }

        let slope = median(lines.filter { $0.box.width > 0.18 }.map(\.slope)) ?? 0
        let lineHeight = median(lines.map(\.box.height)) ?? 0.02

        // Where the line's vertical centre would be at the left edge of the
        // page, if the page were level.
        func level(_ line: ReceiptTextLine) -> CGFloat {
            line.box.midY - slope * line.box.midX
        }

        var groups: [[ReceiptTextLine]] = []
        var anchors: [CGFloat] = []

        for line in lines.sorted(by: { level($0) < level($1) }) {
            let key = level(line)
            let reach = max(lineHeight, line.box.height) * 0.55

            // The last two rows, not just the last: a short price and a tall
            // name on the same row can project a hair apart, and a line from
            // the row below can land between them.
            let candidates = groups.indices.suffix(2).filter { index in
                abs(anchors[index] - key) < reach
                    && !groups[index].contains { sidewaysOverlap($0.box, line.box) > 0.3 }
            }

            if let index = candidates.min(by: { abs(anchors[$0] - key) < abs(anchors[$1] - key) }) {
                groups[index].append(line)
                anchors[index] = groups[index].map { level($0) }.reduce(0, +) / CGFloat(groups[index].count)
            } else {
                groups.append([line])
                anchors.append(key)
            }
        }

        return groups.enumerated().map { index, members in
            let ordered = members.sorted { $0.box.minX < $1.box.minX }
            let box = ordered.dropFirst().reduce(ordered[0].box) { $0.union($1.box) }
            return ReceiptRow(
                id: index,
                page: page,
                cells: ordered.map {
                    ReceiptCell(
                        text: $0.text,
                        alternatives: $0.alternatives,
                        minX: $0.box.minX,
                        maxX: $0.box.maxX,
                        height: $0.box.height,
                        isTitle: $0.isTitle
                    )
                },
                box: box
            )
        }
    }

    /// Several photographs of one long receipt, as one receipt.
    ///
    /// People overlap the shots so nothing is missed, which means the bottom
    /// rows of one page are usually the top rows of the next. Reading both
    /// would bill the overlapping items twice.
    static func stitch(_ pages: [[ReceiptRow]]) -> [ReceiptRow] {
        var combined: [ReceiptRow] = []

        for page in pages {
            var incoming = page
            let limit = min(8, combined.count, incoming.count)

            if limit >= 2 {
                for size in stride(from: limit, through: 2, by: -1) {
                    let tail = combined.suffix(size).map { normalised($0.text) }
                    let head = incoming.prefix(size).map { normalised($0.text) }
                    if tail == head {
                        incoming.removeFirst(size)
                        break
                    }
                }
            }
            combined.append(contentsOf: incoming)
        }

        return combined.enumerated().map { index, row in
            var row = row
            row.id = index
            return row
        }
    }

    // MARK: - Helpers

    static func normalised(_ text: String) -> String {
        String(text.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    private static func sidewaysOverlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let overlap = min(a.maxX, b.maxX) - max(a.minX, b.minX)
        guard overlap > 0 else { return 0 }
        return overlap / max(0.0001, min(a.width, b.width))
    }

    private static func median(_ values: [CGFloat]) -> CGFloat? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }
}
