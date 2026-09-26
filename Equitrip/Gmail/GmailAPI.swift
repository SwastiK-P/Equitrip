//
//  GmailAPI.swift
//  Equitrip
//

import Foundation

/// The two Gmail calls this app makes: list the ids, fetch the messages.
///
/// No history API, deliberately. `users.history.list` is the efficient way to
/// stay in sync with a mailbox, but it needs a `historyId` that goes stale
/// after about a week of not asking, and its failure mode is a silent gap in
/// what you fetched. A date-bounded search re-run each time is a few more
/// bytes and cannot lose a message — and the window is only ever as wide as a
/// trip, so "a few more bytes" is measured in kilobytes.
enum GmailAPI {

    private static let base = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me")!

    /// The search Gmail itself runs, before anything is downloaded.
    ///
    /// Two jobs. The exclusions throw away the three categories a payment
    /// alert is never in — a bank alert lands in Primary or Updates, never in
    /// Promotions — and the `{…}` group is Gmail's OR: a message must contain
    /// at least one of the words a debit notice always contains. This is the
    /// cheapest filter in the pipeline and by far the widest: it is the reason
    /// the on-device model sees a handful of emails a day rather than all of
    /// them.
    ///
    /// It is deliberately *loose* about what counts as a payment word and
    /// strict about the categories. A missed expense is a tap in quick add; a
    /// mailbox trawled in full is a battery complaint.
    nonisolated static let paymentQuery = """
        -category:promotions -category:social -category:forums -in:spam -in:trash \
        {"debited" "has been debited" "debited from" "paid to" "payment of" "you paid" \
        "transaction alert" "txn" "UPI" "spent on" "charged" "withdrawn" "purchase of"}
        """

    /// The search for booking changes — the same category exclusions, and a
    /// message must say something was cancelled, moved or amended. Loose on
    /// purpose, like `paymentQuery`: every confirmation that mentions "free
    /// cancellation" comes through here, and `BookingMailGate` is what turns
    /// those away, with its reason.
    nonisolated static let bookingChangeQuery = """
        -category:promotions -category:social -category:forums -in:spam -in:trash \
        {"cancelled" "canceled" "cancellation" "rescheduled" "reschedule" "schedule change" \
        "time change" "revised" "modified" "modification" "amended" "has been changed" "delayed" \
        "preponed" "postponed" "booking updated"}
        """

    /// Message ids matching the payment query in a time window.
    ///
    /// `after:` and `before:` take epoch seconds and are inclusive of the day
    /// boundary in the account's timezone, which is close enough — the window
    /// is re-checked against the trip's real dates once the message is read.
    static func messageIDs(
        token: String,
        query search: String = paymentQuery,
        after: Date,
        before: Date? = nil,
        limit: Int = 40
    ) async throws -> [String] {
        var query = "\(search) after:\(Int(after.timeIntervalSince1970))"
        if let before {
            query += " before:\(Int(before.timeIntervalSince1970) + 86_400)"
        }

        var components = URLComponents(url: base.appending(path: "messages"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "q", value: query),
            .init(name: "maxResults", value: String(limit))
        ]

        struct Listing: Decodable {
            struct Ref: Decodable { let id: String }
            let messages: [Ref]?
        }

        let data = try await get(components.url!, token: token)
        guard let listing = try? JSONDecoder().decode(Listing.self, from: data) else {
            throw GmailError.decoding
        }
        return (listing.messages ?? []).map(\.id)
    }

    static func message(id: String, token: String) async throws -> MailMessage? {
        var components = URLComponents(
            url: base.appending(path: "messages").appending(path: id),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [.init(name: "format", value: "full")]

        let data = try await get(components.url!, token: token)
        guard let payload = try? JSONDecoder().decode(GmailMessagePayload.self, from: data) else {
            throw GmailError.decoding
        }
        return payload.makeMessage()
    }

    /// Fetched a few at a time. Gmail's per-user rate limit is generous but
    /// not infinite, and forty simultaneous requests from a phone on hotel
    /// wifi is how you earn a 429.
    static func messages(ids: [String], token: String, width: Int = 4) async throws -> [MailMessage] {
        var collected: [MailMessage] = []

        for chunk in stride(from: 0, to: ids.count, by: width).map({ Array(ids[$0..<min($0 + width, ids.count)]) }) {
            try await withThrowingTaskGroup(of: MailMessage?.self) { group in
                for id in chunk {
                    group.addTask { try? await message(id: id, token: token) }
                }
                for try await message in group {
                    if let message { collected.append(message) }
                }
            }
        }

        return collected.sorted { $0.receivedAt > $1.receivedAt }
    }

    private static func get(_ url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw GmailError.http(status, String(data: data.prefix(200), encoding: .utf8) ?? "")
        }
        return data
    }
}
