//
//  CoverImage.swift
//  EquitripWatch Watch App
//

import CryptoKit
import ImageIO
import SwiftUI

/// A trip's cover photo, on the wrist.
///
/// The phone sends a URL rather than the picture — the application context
/// is for a few kilobytes of state, not a photograph — so the watch fetches
/// it once, shrinks it to what a watch screen can show, and keeps that on
/// disk. A cover changes rarely and is looked at constantly; the second look
/// should never wait on the network.
struct CoverImage: View {
    let url: URL?
    /// Drawn while the photo loads, and in its place when there is none.
    var symbol: String?

    @State private var image: UIImage?

    var body: some View {
        // An overlay, not a ZStack: a filled image in a stack sizes the stack
        // to the photo and spills past whatever frame the caller set. As an
        // overlay it takes the fallback's size — the caller's frame — and is
        // clipped to it.
        fallback
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .clipped()
        .task(id: url) {
            guard let url else { image = nil; return }
            let loaded = await CoverCache.shared.image(for: url)
            withAnimation(.easeOut(duration: 0.25)) { image = loaded }
        }
        .accessibilityHidden(true)
    }

    /// The same deepening accent the phone's `DestinationImage` falls back
    /// to, with the trip's own glyph — a cover-shaped thing, never a grey box.
    private var fallback: some View {
        LinearGradient(
            colors: [Brand.accent.opacity(0.55), Brand.accentDeep.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: symbol ?? "airplane")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}

// MARK: - Cache

/// Memory first, then the caches directory, then the network — and every
/// image stored already shrunk, so a 1,080px cover costs a watch's worth of
/// pixels in both places.
actor CoverCache {
    static let shared = CoverCache()

    /// Longest edge, in pixels. Twice the widest a cover is ever drawn on the
    /// largest watch, which is as sharp as the screen can show it.
    private let maxPixelSize = 420

    private var memory: [URL: UIImage] = [:]
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private let directory: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("covers", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    func image(for url: URL) async -> UIImage? {
        if let cached = memory[url] { return cached }
        // Two views asking for the same cover at once — the card and the
        // picker — share one download.
        if let running = inFlight[url] { return await running.value }

        let task = Task { await load(url) }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        memory[url] = image
        return image
    }

    private func load(_ url: URL) async -> UIImage? {
        let file = directory.appendingPathComponent(Self.key(for: url))

        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            return image
        }

        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let shrunk = shrink(data)
        else { return nil }

        let image = UIImage(cgImage: shrunk)
        if let jpeg = image.jpegData(compressionQuality: 0.8) {
            try? jpeg.write(to: file, options: .atomic)
        }
        return image
    }

    /// Decoded straight to the small size by ImageIO, so the full-size
    /// photo is never held in memory on the watch at all.
    private func shrink(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// Stable across launches, unlike `hashValue`, and safe as a file name
    /// whatever the URL contains. The query stays in: a replaced custom
    /// cover keeps its path and changes only its `?v=` token.
    private static func key(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined() + ".jpg"
    }
}
