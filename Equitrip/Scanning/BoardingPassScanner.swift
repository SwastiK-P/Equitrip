//
//  BoardingPassScanner.swift
//  Equitrip
//

import SwiftUI
import VisionKit
import Vision

/// Scans a boarding pass with the camera and pulls the flight number off it.
///
/// Entirely on-device: the document camera captures a page, Vision's text
/// recognizer reads it, and a pattern match picks the flight number out of
/// whatever else is printed on the pass. Nothing is uploaded — the same
/// on-device principle as the PDF import, just pointed at a camera instead
/// of a file.
struct BoardingPassScanner: UIViewControllerRepresentable {
    var onScanned: (String) -> Void
    var onCancel: () -> Void
    var onFailure: (String) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, onCancel: onCancel, onFailure: onFailure)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanned: (String) -> Void
        let onCancel: () -> Void
        let onFailure: (String) -> Void

        init(onScanned: @escaping (String) -> Void, onCancel: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
            self.onScanned = onScanned
            self.onCancel = onCancel
            self.onFailure = onFailure
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                onFailure("Nothing was captured.")
                return
            }
            let image = scan.imageOfPage(at: 0)

            Task {
                if let number = await BoardingPassReader.flightNumber(in: image) {
                    onScanned(number)
                } else {
                    onFailure("Couldn't find a flight number on that page. Try getting the whole barcode strip in frame.")
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onFailure("The camera couldn't scan that.")
        }
    }
}

/// The OCR-and-pattern-match half of scanning: given a photo of a document,
/// find the token on it that looks like a flight number.
enum BoardingPassReader {
    static func flightNumber(in image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        let lines: [String] = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: strings)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }

        return extractFlightNumber(from: lines)
    }

    /// Boarding passes print the flight number next to the word "Flight" far
    /// more reliably than anywhere else on the page, so a labelled line is
    /// tried first; a bare-pattern scan across every line is the fallback for
    /// passes that only show it once, unlabelled.
    static func extractFlightNumber(from lines: [String]) -> String? {
        let labelPattern = try? NSRegularExpression(
            pattern: "FLIGHT\\s*[:\\-]?\\s*([A-Z0-9]{2}\\s?-?\\s?\\d{1,4})",
            options: .caseInsensitive
        )
        let barePattern = try? NSRegularExpression(
            pattern: "\\b([A-Z]{2}\\d?|\\d[A-Z])\\s?-?\\s?(\\d{2,4})\\b"
        )

        for line in lines {
            let upper = line.uppercased()
            guard upper.contains("FLIGHT") else { continue }
            if let match = firstMatch(labelPattern, in: line, groupIndex: 1) {
                return FlightLookupService.display(match)
            }
        }

        for line in lines {
            if let match = firstMatch(barePattern, in: line, groupIndex: 0) {
                return FlightLookupService.display(match)
            }
        }

        return nil
    }

    private static func firstMatch(_ regex: NSRegularExpression?, in text: String, groupIndex: Int) -> String? {
        guard let regex else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        let target = groupIndex < match.numberOfRanges ? match.range(at: groupIndex) : match.range
        guard let swiftRange = Range(target, in: text) else { return nil }
        return String(text[swiftRange])
    }
}
