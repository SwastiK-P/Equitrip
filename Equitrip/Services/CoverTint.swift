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
actor CoverTint {
    static let shared = CoverTint()

    private var cache: [String: Color] = [:]
    /// No colour management on the way in — we want the pixels as they are,
    /// and skipping the conversion keeps the render to a single 1×1 sample.
    private let context = CIContext(options: [.workingColorSpace: NSNull()])

    func tint(for photo: TripPhoto) async -> Color? {
        // The thumbnail averages to the same colour as the full image and is
        // a fraction of the bytes, so prefer it when there is one.
        await tint(for: photo.thumbURL ?? photo.url)
    }

    func tint(for url: URL) async -> Color? {
        let key = url.absoluteString
        if let hit = cache[key] { return hit }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data),
              let source = CIImage(image: image),
              let swatch = average(of: source)
        else { return nil }

        cache[key] = swatch
        return swatch
    }

    private func average(of image: CIImage) -> Color? {
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

        return Color(uiColor: UIColor(
            hue: hue,
            saturation: lift,
            brightness: min(max(brightness * 1.15, 0.5), 0.86),
            alpha: 1
        ))
    }
}
