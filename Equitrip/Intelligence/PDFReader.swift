//
//  PDFReader.swift
//  Equitrip
//

import PDFKit
import Foundation

/// Pulls readable text out of a picked document.
enum PDFReader {
    enum ReadError: LocalizedError {
        case unreadable
        case noText
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .unreadable: "That file couldn't be opened as a PDF."
            case .noText: "This PDF has no selectable text — it's likely a scan."
            case .permissionDenied: "Couldn't get permission to read that file."
            }
        }

        var recovery: String {
            switch self {
            case .noText: "Add the trip manually instead, or export a text-based PDF from your booking email."
            default: "Try another file, or add the trip manually."
            }
        }
    }

    static func text(at url: URL) throws -> String {
        // Files picked from the Files app arrive security-scoped.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let document = PDFDocument(url: url) else { throw ReadError.unreadable }

        var pages: [String] = []
        for index in 0..<document.pageCount {
            if let page = document.page(at: index), let text = page.string {
                pages.append(text)
            }
        }

        let combined = pages.joined(separator: "\n")
        let stripped = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        guard stripped.count > 40 else { throw ReadError.noText }

        return collapseWhitespace(stripped)
    }

    /// Booking PDFs are laid out in tables, so raw extraction is full of runs
    /// of spaces and blank lines. Collapsing them saves a lot of context.
    private static func collapseWhitespace(_ text: String) -> String {
        text
            .replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: " *\\n *", with: "\n", options: .regularExpression)
    }
}
