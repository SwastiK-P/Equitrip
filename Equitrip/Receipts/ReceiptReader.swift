//
//  ReceiptReader.swift
//  Equitrip
//

import SwiftUI

/// Drives one receipt from photograph to `ReceiptScan`, and says what it's doing.
///
/// The stages are real, not decoration, and each exists to stop a particular
/// failure:
///
/// 1. **Straighten** — `ReceiptImagePrep` finds the paper and flattens it, so
///    rows are rows.
/// 2. **Read** — `ReceiptOCR` with iOS 26's document recogniser: text with
///    positions and alternative readings, not a blob of text.
/// 3. **Understand** — `ReceiptLayout` rebuilds rows from positions,
///    `ReceiptParser` reads them by rule, and `ReceiptInterpreter` has Apple
///    Intelligence relabel them.
/// 4. **Check** — `ReceiptReconciler` makes the numbers agree. When neither
///    reading adds up, the page is read a second time with language
///    correction off, those readings join the alternatives, and the whole
///    thing is tried again.
///
/// Everything happens on this device. The only thing that ever leaves it is
/// the photo, uploaded with the expense it seeds.
@MainActor
@Observable
final class ReceiptReader {

    enum Stage: Int, Comparable, CaseIterable {
        case straightening, reading, understanding, checking, finished

        static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// A line of text found on a page, for the reading screen to light up.
    struct Mark: Identifiable, Hashable {
        let id: Int
        let page: Int
        /// Normalised to the page, origin top-left.
        let box: CGRect
        var tone: Tone
    }

    enum Tone: Hashable { case text, item, charge, total }

    private(set) var stage: Stage = .straightening
    /// The straightened pages, in colour: what's shown and what's attached.
    private(set) var pages: [UIImage] = []
    private(set) var marks: [Mark] = []
    private(set) var lineCount = 0
    private(set) var result: ReceiptScan?
    private(set) var failure: String?
    private(set) var isTakingSecondLook = false

    var usesModel: Bool { ReceiptInterpreter.isAvailable }

    func read(_ captures: [UIImage], alreadyRectified: Bool) async {
        stage = .straightening
        failure = nil
        result = nil

        var readable: [CGImage] = []
        for capture in captures {
            guard let upright = ReceiptImagePrep.upright(capture) else { continue }
            let prepared = await ReceiptImagePrep.prepare(upright, alreadyRectified: alreadyRectified)
            pages.append(UIImage(cgImage: prepared.display))
            readable.append(prepared.reading)
        }
        guard !readable.isEmpty else {
            failure = "That image couldn't be opened."
            return
        }

        stage = .reading
        var pageLines: [[ReceiptTextLine]] = []
        for (index, image) in readable.enumerated() {
            let lines = await ReceiptOCR.lines(in: image)
            pageLines.append(lines)
            lineCount += lines.count
            marks.append(contentsOf: lines.enumerated().map { offset, line in
                Mark(id: marks.count + offset, page: index, box: line.box, tone: .text)
            })
        }
        guard lineCount > 0 else {
            failure = "No printed text was found. Try again with the whole receipt in frame and some light on it."
            return
        }

        stage = .understanding
        var best = await understand(pageLines, secondLook: false)

        stage = .checking
        if !(best?.check.addsUp ?? false) {
            // Neither reading adds up. Read the page again with language
            // correction off — the setting that turns "1O5.OO" into a word —
            // and let those readings compete as alternatives.
            isTakingSecondLook = true
            var widened: [[ReceiptTextLine]] = []
            for (index, image) in readable.enumerated() {
                widened.append(await ReceiptOCR.secondOpinion(on: image, merging: pageLines[index]))
            }
            if let second = await understand(widened, secondLook: true),
               ReceiptReconciler.rank(second) < (best.map { ReceiptReconciler.rank($0) } ?? .infinity) {
                best = second
            }
            isTakingSecondLook = false
        }

        guard let best, !(best.lines.isEmpty && best.total == nil) else {
            failure = "Couldn't find any prices on that. A receipt photographed flat, filling the frame, reads best."
            return
        }

        result = best
        stage = .finished
    }

    /// Rules first, then the model, and whichever of the two adds up better.
    private func understand(_ pageLines: [[ReceiptTextLine]], secondLook: Bool) async -> ReceiptScan? {
        let rows = ReceiptLayout.stitch(pageLines.enumerated().map { ReceiptLayout.rows(from: $1, page: $0) })
        guard !rows.isEmpty else { return nil }

        let parse = ReceiptParser.parse(rows)
        var scan = ReceiptReconciler.reconcile(parse, tookSecondLook: secondLook)
        var chosen = parse

        if let relabelled = await ReceiptInterpreter.interpret(parse) {
            let modelled = ReceiptReconciler.reconcile(relabelled, tookSecondLook: secondLook)
            // Ties go to the model: when both add up, it's the one that
            // understood "Kingfisher Ultra" is a beer rather than a code.
            if ReceiptReconciler.rank(modelled) <= ReceiptReconciler.rank(scan) {
                scan = modelled
                chosen = relabelled
            } else {
                // Its merchant and category are still better guesses than
                // the rules', even when its row labels weren't — and
                // `interpret` only lets it change a category the rules
                // couldn't place.
                scan.merchant = relabelled.merchant
                scan.kind = relabelled.kind
            }
        }

        colour(chosen, scan: scan)
        return scan
    }

    /// Recolours the reading screen's marks by what each row turned out to be.
    private func colour(_ parse: ReceiptParse, scan: ReceiptScan) {
        let itemSources = Set(scan.lines.map(\.source))
        var tones: [Int: [CGRect: Tone]] = [:]

        for row in parse.rows {
            let tone: Tone
            if row.role == .item, itemSources.contains(row.row.text) {
                tone = .item
            } else if row.role.chargeKind != nil || row.role == .subtotal {
                tone = .charge
            } else if row.role == .total {
                tone = .total
            } else {
                continue
            }
            tones[row.row.page, default: [:]][row.row.box] = tone
        }

        marks = marks.map { mark in
            var mark = mark
            if let rowBoxes = tones[mark.page],
               let match = rowBoxes.first(where: { $0.key.insetBy(dx: -0.002, dy: -0.002).contains(mark.box.center) }) {
                mark.tone = match.value
            }
            return mark
        }
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
