//
//  PayeeReader.swift
//  Equitrip
//

import Foundation

/// Who the money went to, pulled out of the email by shape.
///
/// The first version of this looked for anything shaped like `name@handle` and
/// took the first hit, which put **alerts@hdfcbank** on three cards in a row —
/// the bank's own From address, matched a character early because the domain
/// pattern stopped at the dot in `hdfcbank.net` and the word boundary was
/// happy to end there. Two lessons, both encoded below: never read the
/// headers, and never accept a handle that is really the front half of a
/// domain.
///
/// What it looks for, in order of how much it tells a person:
///
///  1. A human name the bank put beside the VPA — `paytmqr70yle0@ptys
///     (ASADULLA SEKH)`. This is the only part of a UPI alert anybody
///     recognises, and every major Indian bank includes it when the payee has
///     one registered.
///  2. A merchant named after a card verb — `spent at STARBUCKS ON`.
///  3. The VPA itself, which is at least addressable.
///
/// Bank-agnostic by construction: these are NPCI and card-network conventions,
/// not one issuer's template.
enum PayeeReader {

    /// `body` and `subject` only — never `readableText`, which carries the
    /// From header and is how the bank's own address got in.
    static func payee(in text: String, excluding senderAddress: String) -> String {
        if let named = nameBesideHandle(in: text) { return named }
        if let merchant = merchantAfterVerb(in: text) { return merchant }
        if let handle = vpa(in: text, excluding: senderAddress) { return handle }
        return ""
    }

    /// `something@bank (RAVI KUMAR)` → `RAVI KUMAR`.
    private static func nameBesideHandle(in text: String) -> String? {
        let patterns = [
            #"@[A-Za-z]{2,20}\s*\(\s*([^)]{2,48}?)\s*\)"#,
            // "towards VPA xyz@bank (NAME)" written the other way round:
            // "(VPA: xyz@bank) NAME" is rarer but does happen.
            #"\bpaid\s+to\s*[:\-]?\s*([A-Za-z][A-Za-z .&'-]{2,48}?)\s*(?:\(|,|\.|\n|$)"#,
            #"\b(?:payee|merchant|beneficiary)\s*(?:name)?\s*[:\-]\s*([^\n]{2,48}?)\s*(?:\(|,|\.|\n|$)"#,
            // Wallets and apps put the amount between the verb and the payee:
            // "You paid Rs.220 to Chai Point using Paytm Wallet".
            #"\bpaid\s+(?:rs\.?|inr|₹|\$)?\s*[\d,.]+\s+to\s+([A-Za-z0-9][A-Za-z0-9 .&'-]{2,40}?)\s*(?:\busing\b|\bon\b|\bvia\b|,|\.|\n|$)"#
        ]

        for pattern in patterns {
            guard let value = firstGroup(pattern, in: text) else { continue }
            let cleaned = tidy(value)
            // A capture that is itself a handle isn't a name, and "VPA" or
            // "UPI" captured out of a label is worse than nothing.
            guard cleaned.count >= 3, !cleaned.contains("@"),
                  cleaned.rangeOfCharacter(from: .letters) != nil,
                  !["vpa", "upi", "n a", "na"].contains(cleaned.lowercased())
            else { continue }
            return cleaned
        }
        return nil
    }

    /// Card alerts: "spent at BLUE TOKAI on 12-09" / "purchase at IRCTC".
    private static func merchantAfterVerb(in text: String) -> String? {
        let patterns = [
            #"\b(?:spent|used|charged)\s+(?:at|on|in)\s+([A-Za-z0-9][A-Za-z0-9 .&'*-]{2,40}?)\s*(?:\bon\b|\bat\b|,|\.|\n|$)"#,
            #"\bpurchase\s+at\s+([A-Za-z0-9][A-Za-z0-9 .&'*-]{2,40}?)\s*(?:\bon\b|,|\.|\n|$)"#,
            #"\btransaction\s+at\s+([A-Za-z0-9][A-Za-z0-9 .&'*-]{2,40}?)\s*(?:\bon\b|,|\.|\n|$)"#
        ]

        for pattern in patterns {
            guard let value = firstGroup(pattern, in: text) else { continue }
            let cleaned = tidy(value)
            // "spent on your card" is the verb followed by the instrument, not
            // a merchant.
            let notAMerchant = ["your card", "your account", "card", "account", "atm", "pos"]
            guard cleaned.count >= 3, !notAMerchant.contains(cleaned.lowercased()) else { continue }
            return cleaned
        }
        return nil
    }

    /// A UPI handle, which is not an email address and not the front of one.
    ///
    /// The lookahead is doing the important work: without it, `alerts@hdfcbank`
    /// matches inside `alerts@hdfcbank.net` and the app reports paying the
    /// bank's mail server.
    private static func vpa(in text: String, excluding senderAddress: String) -> String? {
        let pattern = #"\b([a-zA-Z0-9][a-zA-Z0-9._-]{2,49}@[a-zA-Z]{2,20})\b(?![.\w@])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let sender = senderAddress.lowercased()
        let senderLocalPart = sender.split(separator: "@").first.map(String.init) ?? ""

        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range(at: 1), in: text) else { continue }
            let handle = String(text[range])
            let lower = handle.lowercased()

            // Not the bank's own address, in whole or in part.
            guard !sender.hasPrefix(lower), lower != sender,
                  !(senderLocalPart.isEmpty ? false : lower.hasPrefix(senderLocalPart + "@"))
            else { continue }

            // A VPA's handle is a bank shortcode — okhdfcbank, ybl, ptys, axl.
            // A mail domain that survived the lookahead (someone@gmail written
            // with no TLD) is not a payee.
            let handleSuffix = lower.split(separator: "@").last.map(String.init) ?? ""
            guard !["gmail", "yahoo", "outlook", "hotmail", "icloud", "proton"].contains(handleSuffix) else { continue }

            return handle
        }
        return nil
    }

    /// Whether the mail names a VPA at all — the strongest signal that a
    /// payment was UPI, regardless of what any model thinks.
    static func mentionsVPA(in text: String, excluding senderAddress: String) -> Bool {
        vpa(in: text, excluding: senderAddress) != nil
    }

    // MARK: - Helpers

    private static func firstGroup(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func tidy(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\n.,;:-–—'\"()"))
    }
}
