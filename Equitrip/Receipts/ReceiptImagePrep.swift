//
//  ReceiptImagePrep.swift
//  Equitrip
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Gets a photograph of a receipt into the shape text recognition reads best.
///
/// A receipt photographed on a restaurant table is small in frame, at an
/// angle, and printed in fading thermal ink. Recognition on that is where the
/// wrong digit comes from, and a wrong digit is the one mistake the rest of
/// the pipeline can only catch, not fix. So before anything is read: the
/// paper is found and flattened, small captures are enlarged, and the ink is
/// pushed apart from the paper.
///
/// Two outputs, deliberately. The straightened colour image is what people
/// see and what gets attached to the expense; the enhanced grey one exists
/// only to be read and would look like a photocopy if anyone saw it.
nonisolated enum ReceiptImagePrep {

    struct Prepared: Sendable {
        let display: CGImage
        let reading: CGImage
    }

    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Draws the picture upright at a sane size. `UIImage` keeps orientation
    /// as a flag beside pixels that are still sideways, and Vision reads the
    /// pixels.
    static func upright(_ image: UIImage, maxDimension: CGFloat = 3200) -> CGImage? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
            .cgImage
    }

    /// Straightens and enhances one page.
    ///
    /// `alreadyRectified` is true for the document camera, which has done its
    /// own edge detection and perspective correction; finding the paper again
    /// inside an image that is already only paper crops receipts to their
    /// densest block of text.
    @concurrent
    static func prepare(_ image: CGImage, alreadyRectified: Bool) async -> Prepared {
        var working = CIImage(cgImage: image)

        if !alreadyRectified, let flattened = await flatten(working) {
            working = flattened
        }

        working = enlargeIfSmall(working)

        let display = render(working) ?? image
        let reading = render(enhance(working)) ?? display
        return Prepared(display: display, reading: reading)
    }

    // MARK: - Finding the paper

    /// The receipt's four corners, pulled square.
    ///
    /// Only trusted when the detected quadrilateral is a plausible piece of
    /// paper: big enough to be the subject of the photo, and not the whole
    /// frame (which is what the detector answers for a screenshot).
    private static func flatten(_ image: CIImage) async -> CIImage? {
        guard let cgImage = render(image) else { return nil }

        let size = image.extent.size
        guard let corners = await paperCorners(in: cgImage, size: size) else { return nil }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = corners[0]
        filter.topRight = corners[1]
        filter.bottomRight = corners[2]
        filter.bottomLeft = corners[3]
        guard let output = filter.outputImage else { return nil }
        return output.transformed(by: CGAffineTransform(translationX: -output.extent.minX, y: -output.extent.minY))
    }

    /// Top-left, top-right, bottom-right, bottom-left, in Core Image's
    /// bottom-left-origin pixel space.
    ///
    /// The document segmenter first: it's a learned model and finds paper on
    /// busy tablecloths. It needs the Neural Engine, though, and where there
    /// isn't one — the Simulator, some older hardware — it fails without a
    /// word, and an unflattened photo is exactly what turned a clean receipt
    /// into a column of misread prices in testing. The classic rectangle
    /// detector is the fallback: plain image processing, runs anywhere, and
    /// good at the case that matters most — white paper on a darker surface.
    static func paperCorners(in image: CGImage, size: CGSize) async -> [CGPoint]? {
        func pixels(_ points: [NormalizedPoint]) -> [CGPoint] {
            points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
        }

        if let found = try? await DetectDocumentSegmentationRequest().perform(on: image), found.confidence > 0.6 {
            let corners = pixels([found.topLeft, found.topRight, found.bottomRight, found.bottomLeft])
            if isPlausiblePaper(corners, in: size) { return corners }
        }

        var rectangles = DetectRectanglesRequest()
        rectangles.minimumAspectRatio = 0.08
        rectangles.maximumAspectRatio = 1
        rectangles.quadratureToleranceDegrees = 35
        rectangles.minimumSize = 0.3
        rectangles.minimumConfidence = 0.5
        rectangles.maximumObservations = 3

        let found = (try? await rectangles.perform(on: image)) ?? []
        let candidates = found
            .map { pixels([$0.topLeft, $0.topRight, $0.bottomRight, $0.bottomLeft]) }
            .filter { isPlausiblePaper($0, in: size) }
        return candidates.max { polygonArea($0) < polygonArea($1) }
    }

    /// Big enough to be the subject, not the whole frame, and taller than it
    /// is wide. The last rule is the one that matters on a receipt already
    /// filling the frame: the detector would sometimes answer with the band
    /// between two rules — just "TOTAL" and the card line — and flattening to
    /// that threw away every item.
    private static func isPlausiblePaper(_ corners: [CGPoint], in size: CGSize) -> Bool {
        let area = polygonArea(corners)
        let frame = size.width * size.height
        guard area > frame * 0.18 && area < frame * 0.94 else { return false }

        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
        let width = (distance(corners[0], corners[1]) + distance(corners[3], corners[2])) / 2
        let height = (distance(corners[0], corners[3]) + distance(corners[1], corners[2])) / 2
        return height >= width * 0.9
    }

    private static func polygonArea(_ points: [CGPoint]) -> CGFloat {
        var sum: CGFloat = 0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            sum += a.x * b.y - b.x * a.y
        }
        return abs(sum) / 2
    }

    // MARK: - Legibility

    /// Recognition wants a character to be a couple of dozen pixels tall. A
    /// receipt that fills a third of a 12MP frame is well over that; a
    /// screenshot of a delivery app's bill often isn't.
    private static func enlargeIfSmall(_ image: CIImage) -> CIImage {
        let width = image.extent.width
        guard width > 0, width < 1100 else { return image }

        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = Float(min(2.4, 1400 / width))
        filter.aspectRatio = 1
        return filter.outputImage ?? image
    }

    /// Grey, firmer contrast, sharper strokes. Not binarised: thresholding a
    /// crumpled receipt turns every shadow into a smear of black that reads
    /// as characters, where the recogniser handles soft grey well.
    private static func enhance(_ image: CIImage) -> CIImage {
        let tone = CIFilter.colorControls()
        tone.inputImage = image
        tone.saturation = 0
        tone.contrast = 1.18
        tone.brightness = 0.02

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = tone.outputImage
        sharpen.sharpness = 0.45
        sharpen.radius = 1.6

        return sharpen.outputImage?.cropped(to: image.extent) ?? image
    }

    /// Multi-page captures stacked into one tall image, because an expense
    /// holds a single receipt photo.
    static func combined(_ pages: [UIImage]) -> UIImage? {
        guard pages.count > 1 else { return pages.first }

        let width = pages.map(\.size.width).max() ?? 0
        guard width > 0 else { return pages.first }
        let heights = pages.map { $0.size.height * (width / max(1, $0.size.width)) }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: heights.reduce(0, +)), format: format).image { _ in
            var y: CGFloat = 0
            for (page, height) in zip(pages, heights) {
                page.draw(in: CGRect(x: 0, y: y, width: width, height: height))
                y += height
            }
        }
    }

    private static func render(_ image: CIImage) -> CGImage? {
        context.createCGImage(image, from: image.extent)
    }
}
