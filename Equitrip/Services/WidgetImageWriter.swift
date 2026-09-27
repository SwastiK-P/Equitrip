//
//  WidgetImageWriter.swift
//  Equitrip
//

import UIKit
import WidgetKit

/// Writes the pictures the widgets draw — each trip's cover and the face of
/// everyone waiting on a settlement — into `SharedImages`.
///
/// Runs after every publish, but only fetches what changed: each file has a
/// sidecar naming the source it came from, so an unchanged cover is one file
/// read, not a download. Images are downsized to 240 px: a widget's memory
/// budget is a few megabytes, and a full cover photo alone can blow it.
enum WidgetImageWriter {

    private static var running: Task<Void, Never>?

    /// Square for badges and faces; wide for the Trips widget's full-bleed cover.
    private static let square = CGSize(width: 240, height: 240)
    private static let wide = CGSize(width: 720, height: 420)

    static func update(for trips: [Trip]) {
        var jobs: [(key: String, source: Source, size: CGSize)] = []
        func face(_ person: Traveller) {
            let source: Source = person.avatarURL.map(Source.remote)
                ?? .asset(Traveller.artwork(for: person.asset))
            jobs.append((SharedImages.faceKey(person.id), source, square))
        }
        for trip in trips {
            if let cover = trip.cover {
                jobs.append((SharedImages.coverKey(trip.id), .remote(cover.thumbURL ?? cover.url), square))
                // The full photo, not the thumbnail: it fills a whole widget.
                jobs.append((SharedImages.wideCoverKey(trip.id), .remote(cover.url), wide))
            }
            trip.travellers.prefix(3).forEach(face)
            for settlement in trip.pendingSettlements {
                if let person = trip.traveller(settlement.fromID) { face(person) }
            }
        }

        running?.cancel()
        running = Task {
            var wrote = false
            for job in jobs where !Task.isCancelled {
                if await write(job.key, from: job.source, size: job.size) { wrote = true }
            }
            if wrote { WidgetCenter.shared.reloadAllTimelines() }
        }
    }

    /// Sign-out: nobody's face or trip stays on the home screen.
    static func clear() {
        running?.cancel()
        if let directory = SharedImages.directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    enum Source {
        case remote(URL)
        case asset(String)

        var tag: String {
            switch self {
            case .remote(let url): url.absoluteString
            case .asset(let name): "asset:" + name
            }
        }
    }

    /// True when a new file was written.
    private static func write(_ key: String, from source: Source, size: CGSize) async -> Bool {
        guard let file = SharedImages.fileURL(key), let directory = SharedImages.directory else { return false }
        let sidecar = file.appendingPathExtension("src")
        if (try? String(contentsOf: sidecar, encoding: .utf8)) == source.tag,
           FileManager.default.fileExists(atPath: file.path) {
            return false
        }

        let image: UIImage?
        switch source {
        case .asset(let name):
            image = UIImage(named: name)
        case .remote(let url):
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200
            else { return false }
            image = UIImage(data: data)
        }
        guard let image, let jpeg = downsized(image, to: size)?.jpegData(compressionQuality: 0.8) else { return false }

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            try jpeg.write(to: file, options: .atomic)
            try source.tag.write(to: sidecar, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Centre-cropped to fill `size` — small enough for a widget's few
    /// megabytes of memory.
    private static func downsized(_ image: UIImage, to size: CGSize) -> UIImage? {
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let drawn = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(
                x: (size.width - drawn.width) / 2,
                y: (size.height - drawn.height) / 2,
                width: drawn.width,
                height: drawn.height
            ))
        }
    }
}
