//
//  ReceiptOCR.swift
//  Equitrip
//

import CoreGraphics
import Vision

/// One printed line, and where on the page it sits.
///
/// Position is the point. A receipt is a two-column table drawn with spaces —
/// the name on the left, the price against the right edge — and recognition
/// often returns those as two separate lines. Reading them back in order as
/// plain text is how "Masala Chai" ends up next to the price of the row
/// beneath it; keeping the geometry is what lets `ReceiptLayout` put them
/// back on the same row.
nonisolated struct ReceiptTextLine: Hashable, Sendable {
    var text: String
    /// Vision's other readings of the same characters, best first. A "6" it
    /// wasn't sure wasn't an "8" is here, and `ReceiptReconciler` tries it
    /// when the first reading doesn't add up.
    var alternatives: [String]
    /// Normalised to the page, origin top-left.
    var box: CGRect
    /// Rise over run of the line's top edge, in normalised units with y down.
    var slope: CGFloat
    var confidence: Float
    /// Vision's own judgement that this is a heading — usually the shop's name.
    var isTitle: Bool
}

/// Reads the text off a receipt page, on this device.
///
/// iOS 26's document recogniser first, because it understands the page as a
/// document — headings, paragraphs, tables — rather than as a scatter of
/// strings, and returns several candidate readings for every line. The plain
/// text recogniser is kept as the fallback when that finds nothing, and as the
/// "second opinion" pass: run without language correction, which is the
/// setting that stops "1O5.OO" being autocorrected into a word, its readings
/// are merged in as alternatives for the lines the first pass already found.
nonisolated enum ReceiptOCR {

    /// Words receipts use that a general language model doesn't expect, so
    /// correction doesn't "fix" CGST into CAST.
    private static let vocabulary = [
        "CGST", "SGST", "IGST", "UTGST", "GSTIN", "FSSAI", "HSN", "SAC", "KOT",
        "Subtotal", "Sub Total", "Gratuity", "Round Off", "Roundoff", "Qty",
        "Amt", "Svc", "Pax", "Tendered", "Cess", "VAT", "Nett", "UPI", "RuPay"
    ]

    @concurrent
    static func lines(in image: CGImage) async -> [ReceiptTextLine] {
        let structured = await documentLines(in: image)
        if structured.count >= 3 { return structured }

        let plain = await plainLines(in: image, correcting: true)
        return plain.count > structured.count ? plain : structured
    }

    /// The uncorrected pass, merged into what was already read.
    @concurrent
    static func secondOpinion(on image: CGImage, merging first: [ReceiptTextLine]) async -> [ReceiptTextLine] {
        let raw = await plainLines(in: image, correcting: false)
        guard !raw.isEmpty else { return first }

        var merged = first
        var unmatched: [ReceiptTextLine] = []

        for line in raw {
            guard let index = merged.indices.max(by: { overlap(merged[$0].box, line.box) < overlap(merged[$1].box, line.box) }),
                  overlap(merged[index].box, line.box) > 0.45 else {
                unmatched.append(line)
                continue
            }

            for reading in [line.text] + line.alternatives
            where reading != merged[index].text && !merged[index].alternatives.contains(reading) {
                merged[index].alternatives.append(reading)
            }
        }

        // A line the document pass missed entirely — faint print it judged to
        // be noise — is worth having. Only confident ones, though: the whole
        // reason for the first pass is that it is choosier.
        merged.append(contentsOf: unmatched.filter { $0.confidence > 0.5 })
        return merged
    }

    // MARK: - Document recognition

    private static func documentLines(in image: CGImage) async -> [ReceiptTextLine] {
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.useLanguageCorrection = true
        request.textRecognitionOptions.maximumCandidateCount = 3
        request.textRecognitionOptions.customWords = vocabulary
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        request.barcodeDetectionOptions.enabled = false

        guard let documents = try? await request.perform(on: image) else { return [] }

        var observations: [RecognizedTextObservation] = []
        var seen = Set<UUID>()

        func collect(_ container: DocumentObservation.Container) {
            for line in container.text.lines where seen.insert(line.uuid).inserted {
                observations.append(line)
            }
            // Tables and lists carry their own text. Usually the same
            // observations the page's text already had — the uuid check
            // drops those — but not always.
            for table in container.tables {
                for row in table.rows {
                    for cell in row { collect(cell.content) }
                }
            }
            for list in container.lists {
                for item in list.items { collect(item.content) }
            }
        }

        for document in documents { collect(document.document) }
        return dedupe(observations.compactMap(line(from:)))
    }

    // MARK: - Plain recognition

    private static func plainLines(in image: CGImage, correcting: Bool) async -> [ReceiptTextLine] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = correcting
        request.automaticallyDetectsLanguage = true
        if correcting { request.customWords = vocabulary }

        guard let observations = try? await request.perform(on: image) else { return [] }
        return observations.compactMap(line(from:))
    }

    // MARK: - Conversion

    private static func line(from observation: RecognizedTextObservation) -> ReceiptTextLine? {
        let candidates = observation.topCandidates(3)
        guard let best = candidates.first else { return nil }

        let text = best.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let alternatives = candidates.dropFirst()
            .map { $0.string.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != text }

        // Vision's normalised space has its origin bottom-left. Everything
        // downstream reads a receipt top to bottom, so flip it once, here.
        let rect = observation.boundingBox.cgRect
        let box = CGRect(x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)

        let run = observation.topRight.x - observation.topLeft.x
        let rise = -(observation.topRight.y - observation.topLeft.y)
        let slope = run > 0.02 ? rise / run : 0

        return ReceiptTextLine(
            text: text,
            alternatives: Array(alternatives),
            box: box,
            slope: slope,
            confidence: best.confidence,
            isTitle: observation.isTitle
        )
    }

    /// The same words in the same place, found twice by walking a table and
    /// the page it's on.
    private static func dedupe(_ lines: [ReceiptTextLine]) -> [ReceiptTextLine] {
        var kept: [ReceiptTextLine] = []
        for line in lines {
            let duplicate = kept.contains { $0.text == line.text && overlap($0.box, line.box) > 0.6 }
            if !duplicate { kept.append(line) }
        }
        return kept
    }

    /// Intersection over the smaller of the two areas — two readings of one
    /// line rarely draw identical boxes, and one is often a strict subset.
    private static func overlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }
        let smaller = min(a.width * a.height, b.width * b.height)
        guard smaller > 0 else { return 0 }
        return (intersection.width * intersection.height) / smaller
    }
}
