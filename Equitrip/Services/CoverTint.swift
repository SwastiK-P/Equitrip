//
//  CoverTint.swift
//  Equitrip
//

import CoreImage
import SwiftUI
import UIKit

/// The colour a photograph is, in one swatch.
///
/// Trip cards mount their photo on a tinted panel. Tinting that panel with
/// the trip's assigned colour looked arbitrary — a lavender board under a
/// snowfield — so the panel is drawn from the photograph itself instead, the
/// way a mount is chosen to match a print.
///
/// An average is deliberately muddy, so the raw result is pushed back up in
/// saturation before it's returned: the point is a recognisable *hue*, not a
/// faithful mean. Results are cached by URL, because the answer for a photo
/// never changes and a card can scroll past many times.
///
/// The cache is also kept on disk. Siri draws its cards in the trip's colour,
/// often from a cold background launch with a second or two to answer in, and
/// downloading a photo to average it is the one thing that launch can't
/// afford — so a colour worked out while the app was open is simply read back.
actor CoverTint {
    static let shared = CoverTint()

    private var cache: [String: Color] = [:]
    /// No colour management on the way in — we want the pixels as they are,
    /// and skipping the conversion keeps the render to a single 1×1 sample.
    private let context = CIContext(options: [.workingColorSpace: NSNull()])

    private static let storeKey = "coverTints"
    private static let storeLimit = 80

    /// The thumbnail averages to the same colour as the full image and is a
    /// fraction of the bytes, so it's the one read everywhere.
    static func key(for photo: TripPhoto) -> URL {
        photo.thumbURL ?? photo.url
    }

    func tint(for photo: TripPhoto) async -> Color? {
        await tint(for: Self.key(for: photo))
    }

    func tint(for url: URL) async -> Color? {
        if let hit = cached(for: url) { return hit }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return tint(for: url, data: data)
    }

    /// A colour already worked out, in memory or on disk — never a download.
    func cached(for url: URL) -> Color? {
        let key = url.absoluteString
        if let hit = cache[key] { return hit }
        guard let hex = (UserDefaults.standard.dictionary(forKey: Self.storeKey) as? [String: Int])?[key] else { return nil }
        let swatch = Color(uiColor: UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        ))
        cache[key] = swatch
        return swatch
    }

    /// The colour of image bytes the caller already has — Siri fetches the
    /// thumbnail once and uses it for both the picture and the tint.
    func tint(for url: URL, data: Data) -> Color? {
        if let hit = cached(for: url) { return hit }
        guard let image = UIImage(data: data),
              let source = CIImage(image: image),
              let swatch = average(of: source)
        else { return nil }

        let key = url.absoluteString
        cache[key] = Color(uiColor: swatch)
        remember(swatch, for: key)
        return cache[key]
    }

    private func remember(_ swatch: UIColor, for key: String) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard swatch.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return }
        let hex = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)

        var stored = UserDefaults.standard.dictionary(forKey: Self.storeKey) as? [String: Int] ?? [:]
        // Covers are few and rarely change; a crude cap keeps a long-lived
        // install from carrying every photo it ever averaged.
        if stored.count >= Self.storeLimit { stored.removeAll() }
        stored[key] = hex
        UserDefaults.standard.set(stored, forKey: Self.storeKey)
    }

    private func average(of image: CIImage) -> UIColor? {
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: image,
            kCIInputExtentKey: CIVector(cgRect: image.extent)
        ])
        guard let output = filter?.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let raw = UIColor(
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255,
            alpha: 1
        )

        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard raw.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return nil }

        // A near-grey average — an overcast mountain, a night skyline — has no
        // hue worth amplifying, so it's left alone rather than turned into a
        // wash of whatever noise won the mean.
        let lift = saturation < 0.06 ? saturation : min(max(saturation * 1.9, 0.34), 0.72)

        return UIColor(
            hue: hue,
            saturation: lift,
            brightness: min(max(brightness * 1.15, 0.5), 0.86),
            alpha: 1
        )
    }
}
