//
//  MailMessage.swift
//  Equitrip
//

import Foundation

/// One email, flattened to the four things any of this cares about: who it's
/// from, what it says it's about, when it arrived, and its text.
///
/// The MIME tree is collapsed here rather than downstream because every stage
/// after this one — the gate, the model, the verification — works on a single
/// string, and each of them would otherwise have to know that a bank alert is
/// usually a `multipart/alternative` whose plain-text half is sometimes empty.
struct MailMessage: Identifiable, Hashable {
    let id: String
    let threadID: String
    /// Gmail's own labels. `CATEGORY_PROMOTIONS` on a message is Google's
    /// classifier saying "marketing", and it is right far more often than any
    /// keyword list this app could write.
    let labelIDs: [String]
    let receivedAt: Date
    let fromName: String
    let fromAddress: String
    let subject: String
    /// Gmail's one-line preview. Kept because it's what the review card shows,
    /// and it's already stripped of markup.
    let snippet: String
    /// The body, as text, capped — see `Self.bodyLimit`.
    let body: String

    /// What the reader is actually given: subject and body together, because a
    /// good many bank alerts put the amount in the subject and nowhere else.
    var readableText: String {
        "Subject: \(subject)\nFrom: \(fromName) <\(fromAddress)>\n\n\(body)"
    }

    /// Where a payee may be looked for: everything the bank wrote, and
    /// nothing about the bank. Excluding the From header is not tidiness —
    /// including it is how `alerts@hdfcbank` became a payee.
    var payeeSearchText: String {
        "\(subject)\n\(body)"
    }

    /// A promotional footer can run to tens of kilobytes of legal text, and
    /// the payment sentence is always near the top. Feeding the whole thing to
    /// an on-device model costs seconds and buys nothing.
    static let bodyLimit = 4_000
}

// MARK: - Wire format

/// The shape `users.messages.get?format=full` returns.
struct GmailMessagePayload: Decodable {
    let id: String
    let threadId: String
    let labelIds: [String]?
    let snippet: String?
    let internalDate: String?
    let payload: Part?

    struct Part: Decodable {
        let mimeType: String?
        let filename: String?
        let headers: [Header]?
        let body: Body?
        let parts: [Part]?
    }

    struct Header: Decodable {
        let name: String
        let value: String
    }

    struct Body: Decodable {
        let size: Int?
        let data: String?
    }

    func makeMessage() -> MailMessage? {
        let headers = payload?.headers ?? []
        func header(_ name: String) -> String {
            headers.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value ?? ""
        }

        let (name, address) = MailText.splitSender(header("From"))
        let received = internalDate
            .flatMap(Double.init)
            .map { Date(timeIntervalSince1970: $0 / 1000) } ?? Date()

        return MailMessage(
            id: id,
            threadID: threadId,
            labelIDs: labelIds ?? [],
            receivedAt: received,
            fromName: name,
            fromAddress: address,
            subject: header("Subject"),
            snippet: MailText.decodeEntities(snippet ?? ""),
            body: String(MailText.body(of: payload).prefix(MailMessage.bodyLimit))
        )
    }
}

// MARK: - Text

/// Turning MIME into something a person — or a small language model — can read.
enum MailText {

    /// Depth-first, preferring `text/plain`.
    ///
    /// Banks send `multipart/alternative` with both halves, and the plain half
    /// is the one where the amount isn't wrapped in six nested tables. When
    /// there isn't one — and there often isn't, because the same template is
    /// used for the marketing mail — the HTML is stripped instead.
    static func body(of part: GmailMessagePayload.Part?) -> String {
        guard let part else { return "" }
        if let plain = firstBody(in: part, matching: "text/plain"), !plain.isEmpty { return plain }
        if let html = firstBody(in: part, matching: "text/html") { return stripHTML(html) }
        return ""
    }

    private static func firstBody(in part: GmailMessagePayload.Part, matching mime: String) -> String? {
        // Attachments have a filename and are never the message.
        if (part.filename ?? "").isEmpty,
           part.mimeType?.lowercased().hasPrefix(mime) == true,
           let data = part.body?.data,
           let decoded = decodeBase64URL(data) {
            return tidy(decoded)
        }
        for child in part.parts ?? [] {
            if let found = firstBody(in: child, matching: mime) { return found }
        }
        return nil
    }

    static func decodeBase64URL(_ raw: String) -> String? {
        var padded = raw
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        padded += String(repeating: "=", count: (4 - padded.count % 4) % 4)
        guard let data = Data(base64Encoded: padded, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    /// A regex strip rather than a parser. The output is never rendered — it
    /// is read once and thrown away — so the only requirement is that the
    /// sentence carrying the amount survives with its words in order.
    static func stripHTML(_ html: String) -> String {
        var text = html
        for pattern in ["<script[^>]*>[\\s\\S]*?</script>", "<style[^>]*>[\\s\\S]*?</style>", "<head[^>]*>[\\s\\S]*?</head>", "<!--[\\s\\S]*?-->"] {
            text = text.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        // Block boundaries become newlines, so a table cell holding "₹480" and
        // the next holding "Paid to" don't fuse into one word.
        text = text.replacingOccurrences(
            of: "</(p|div|tr|td|th|li|h[1-6]|table|br)>|<br\\s*/?>",
            with: "\n", options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return tidy(decodeEntities(text))
    }

    static func decodeEntities(_ raw: String) -> String {
        var text = raw
        let map = [
            "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
            "&#39;": "'", "&apos;": "'", "&rupee;": "₹", "&#8377;": "₹", "&#x20B9;": "₹",
            "&ndash;": "–", "&mdash;": "—", "&rsquo;": "'", "&lsquo;": "'"
        ]
        for (entity, glyph) in map {
            text = text.replacingOccurrences(of: entity, with: glyph, options: .caseInsensitive)
        }
        // Anything numeric left over: &#8377; style.
        text = text.replacingOccurrences(of: "&#\\d+;", with: " ", options: .regularExpression)
        return text
    }

    static func tidy(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "[ \\t\\u{00A0}]{2,}", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `"HDFC Bank InstaAlerts" <alerts@hdfcbank.net>` → the two halves.
    static func splitSender(_ raw: String) -> (name: String, address: String) {
        guard let open = raw.lastIndex(of: "<"), let close = raw.lastIndex(of: ">"), open < close else {
            return (raw.trimmingCharacters(in: .whitespaces), raw.trimmingCharacters(in: .whitespaces))
        }
        let address = String(raw[raw.index(after: open)..<close])
        let name = raw[raw.startIndex..<open]
            .trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
        return (name.isEmpty ? address : name, address)
    }
}
