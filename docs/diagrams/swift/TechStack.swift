//
//  TechStack.swift
//  Equitrip — presentation card
//

import SwiftUI
import AppKit

// MARK: - Brand marks

/// Supabase's bolt, from the official two-path mark.
struct SupabaseMark: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / 109, geo.size.height / 113)
            let dx = (geo.size.width - 109 * s) / 2
            let dy = (geo.size.height - 113 * s) / 2

            ZStack {
                bolt(down: true, s: s, dx: dx, dy: dy)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.14, green: 0.58, blue: 0.38),
                                     Color(red: 0.24, green: 0.81, blue: 0.56)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                bolt(down: false, s: s, dx: dx, dy: dy)
                    .fill(Color(red: 0.24, green: 0.81, blue: 0.56))
            }
        }
    }

    private func bolt(down: Bool, s: CGFloat, dx: CGFloat, dy: CGFloat) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s + dx, y: y * s + dy) }
        var path = Path()

        if down {
            path.move(to: p(63.71, 110.28))
            path.addCurve(to: p(54.98, 107.31), control1: p(60.85, 113.89), control2: p(55.05, 111.91))
            path.addLine(to: p(53.97, 40.06))
            path.addLine(to: p(99.19, 40.06))
            path.addCurve(to: p(106.86, 55.94), control1: p(107.38, 40.06), control2: p(111.95, 49.52))
            path.addLine(to: p(63.71, 110.28))
        } else {
            path.move(to: p(45.32, 2.07))
            path.addCurve(to: p(54.04, 5.04), control1: p(48.18, -1.53), control2: p(53.97, 0.44))
            path.addLine(to: p(54.48, 72.29))
            path.addLine(to: p(9.83, 72.29))
            path.addCurve(to: p(2.17, 56.42), control1: p(1.64, 72.29), control2: p(-2.93, 62.83))
            path.addLine(to: p(45.32, 2.07))
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Chip

/// The logo files the user supplied, loaded straight off disk.
enum BrandAsset {
    static let folder = "/Users/swastik/Developer/Equitrip/"

    static func image(_ file: String) -> Image? {
        guard let ns = NSImage(contentsOfFile: folder + file) else { return nil }
        return Image(nsImage: ns)
    }
}

enum BrandMark {
    case gmail                              // drawn from the official geometry
    case asset(String, needsTile: Bool)     // a real logo file
    case symbol(String, [Color])            // glyph on an Apple-style tile
}

/// Renders any mark at a given size, so a chip in the flow diagram and a chip
/// on the stack card show exactly the same artwork.
struct BrandTile: View {
    let mark: BrandMark
    var side: CGFloat = 26

    var body: some View {
        let radius = side * 0.27

        switch mark {
        case .gmail:
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.white)
                .overlay { GmailMark().padding(side * 0.19) }
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(0.1))
                }
                .frame(width: side, height: side)

        case .asset(let file, let needsTile):
            Group {
                if needsTile {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(.white)
                        .overlay {
                            BrandAsset.image(file)?
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(side * 0.16)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(AppTheme.cardStroke.opacity(0.1))
                        }
                } else {
                    BrandAsset.image(file)?
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: side, height: side)

        case .symbol(let name, let colors):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Image(systemName: name)
                        .font(.system(size: side * 0.48, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: side, height: side)
        }
    }
}

struct TechItem: Identifiable {
    var id: String { name }
    let name: String
    let mark: BrandMark
}

struct TechChipLarge: View {
    let item: TechItem

    var body: some View {
        HStack(spacing: 9) {
            tile
            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize()
        }
        .padding(.leading, 9)
        .padding(.trailing, 14)
        .padding(.vertical, 8)
        .cardSurface(corner: 14, shadow: 8)
    }

    private var tile: some View { BrandTile(mark: item.mark, side: 26) }
}

// MARK: - Card

struct TechStackCard: View {
    struct Section: Identifiable {
        var id: String { title }
        let title: String
        let rows: [[TechItem]]
    }

    @ViewBuilder
    private func column(_ sections: [Section]) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.inkTertiary)

                    ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 8) {
                            ForEach(row) { item in
                                TechChipLarge(item: item)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 300, alignment: .topLeading)
    }

    static let swiftOrange = Color(red: 0.94, green: 0.32, blue: 0.22)
    static let swiftUIBlue = Color(red: 0.16, green: 0.55, blue: 0.94)

    static let sections: [Section] = [
        .init(title: "FRONTEND", rows: [
            [
                .init(name: "Swift 6", mark: .asset("swift.png", needsTile: false)),
                .init(name: "SwiftUI", mark: .asset("Swifti.png", needsTile: false))
            ],
            [
                .init(name: "SF Symbols", mark: .symbol("square.grid.2x2.fill", [
                    Color(red: 0.35, green: 0.45, blue: 0.95), Color(red: 0.55, green: 0.35, blue: 0.95)
                ]))
            ]
        ]),

        .init(title: "AI & MACHINE LEARNING  ·  ALL ON-DEVICE", rows: [
            [
                .init(name: "Apple Foundation Models", mark: .asset("Foundation.png", needsTile: false))
            ],
            [
                .init(name: "Vision", mark: .asset("vision.png", needsTile: false)),
                .init(name: "VisionKit", mark: .asset("vision.png", needsTile: false))
            ],
            [
                .init(name: "PDFKit", mark: .symbol("doc.richtext.fill", [
                    Color(red: 0.93, green: 0.42, blue: 0.35), Color(red: 0.85, green: 0.28, blue: 0.30)
                ])),
                .init(name: "Core Image", mark: .symbol("camera.filters", [
                    Color(red: 0.36, green: 0.62, blue: 0.95), Color(red: 0.28, green: 0.45, blue: 0.88)
                ]))
            ]
        ]),

        .init(title: "BACKEND & API SERVICES", rows: [
            [
                .init(name: "Supabase", mark: .asset("supabase.png", needsTile: false)),
                .init(name: "Gmail API", mark: .gmail)
            ],
            [
                .init(name: "AviationStack", mark: .asset("aviationstack.png", needsTile: true))
            ],
            [
                .init(name: "Cloudflare R2", mark: .symbol("shippingbox.fill", [
                    Color(red: 0.96, green: 0.57, blue: 0.18), Color(red: 0.90, green: 0.38, blue: 0.12)
                ]))
            ],
            [
                .init(name: "Unsplash & Pexels", mark: .asset("unplash.png", needsTile: false))
            ]
        ]),

        .init(title: "APPLE PLATFORM", rows: [
            [
                .init(name: "MapKit", mark: .asset("mapkit.png", needsTile: false)),
                .init(name: "APNs", mark: .symbol("bell.badge.fill", [
                    Color(red: 0.95, green: 0.55, blue: 0.20), Color(red: 0.90, green: 0.38, blue: 0.18)
                ]))
            ],
            [
                .init(name: "watchOS", mark: .symbol("applewatch", [
                    Color(red: 0.42, green: 0.44, blue: 0.48), Color(red: 0.24, green: 0.26, blue: 0.30)
                ]))
            ]
        ])
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.canvasTop, AppTheme.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .top, spacing: 32) {
                column(Array(Self.sections.prefix(2)))
                column(Array(Self.sections.suffix(2)))
            }
            .padding(34)
        }
        .frame(width: 700, height: 408)
    }
}
