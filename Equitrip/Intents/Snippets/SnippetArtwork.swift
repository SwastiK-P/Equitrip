//
//  SnippetArtwork.swift
//  Equitrip
//

import SwiftUI
import UIKit

/// The trip's colour and photograph, ready before a snippet is drawn.
///
/// A snippet is rendered by the system from the view the intent hands back, so
/// nothing in it can load later — an `AsyncImage` there stays empty. The
/// picture has to be in hand when `perform()` returns, and `perform()` runs
/// behind a spoken answer. So the thumbnail is fetched once, with a short
/// deadline, and kept for as long as the process lives; a snippet redrawn
/// after a button press finds it already here. If the photo is slow the card
/// goes out in the trip's colour without it, which is a fine card.
@MainActor
enum SnippetArtwork {

    private static var thumbnails: [URL: UIImage] = [:]
    private nonisolated static let deadline: Duration = .milliseconds(1500)

    static func look(for trip: Trip) async -> SnippetLook {
        guard let cover = trip.cover else {
            return SnippetLook(tint: SnippetTint.readable(trip.tint), photo: nil)
        }
        let url = CoverTint.key(for: cover)

        var image = thumbnails[url]
        var tint = await CoverTint.shared.cached(for: url)

        if image == nil, let data = await download(url) {
            image = UIImage(data: data)
            thumbnails[url] = image
            if tint == nil { tint = await CoverTint.shared.tint(for: url, data: data) }
        }

        return SnippetLook(
            tint: SnippetTint.readable(tint ?? trip.tint),
            photo: image.map { Image(uiImage: $0) }
        )
    }

    /// The bytes, or nil if they didn't arrive in time.
    private static func download(_ url: URL) async -> Data? {
        await withTaskGroup(of: Data?.self) { group in
            group.addTask { try? await URLSession.shared.data(from: url).0 }
            group.addTask {
                try? await Task.sleep(for: deadline)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
