import SwiftUI
import AppKit

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)

    let renderer = ImageRenderer(content: EquitripUserFlow())
    renderer.scale = 3
    renderer.isOpaque = false
    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("render failed")
    }
    let path = "/Users/swastik/Developer/Equitrip/docs/equitrip-userflow.png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) — \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)")
}
