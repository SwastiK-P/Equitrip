//
//  SnippetChrome.swift
//  Equitrip
//

import AppIntents
import SwiftUI
import UIKit

/// The card every Siri and Shortcuts answer is drawn on: the trip's own colour,
/// white type, and the figure that matters set large.
///
/// The first snippets were grey system text on Siri's glass. They repeated the
/// spoken dialog in a caption and had nothing of the app in them, and a card
/// that reads like a transcript is one people stop looking at. Apple's snippet
/// guidance asks for the opposite — a vibrant background from the app's own
/// identity, type larger than the system default, nothing taller than about
/// 340 points, and a card that makes sense with the sound off. The identity
/// here is the trip itself: its cover photograph's colour (`CoverTint`), its
/// title in the typeface its organiser picked (`TripTitleStyle`), its photo as
/// the icon.
///
/// Drawn the same in light and dark. The app is light-only but Siri isn't, and
/// a tinted card with white type needs no second palette.
struct SnippetCard<Content: View>: View {
    let look: SnippetLook
    /// The trip photo across the whole card, under a scrim — for the one card
    /// that is about the trip as a place rather than its numbers.
    var fullBleedPhoto = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        // Over a photograph, a soft shadow under the type — the scrim alone
        // loses to a night street full of lights.
        .shadow(color: .black.opacity(fullBleedPhoto && look.photo != nil ? 0.35 : 0), radius: 6, y: 1)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(SnippetInk.primary)
        .tint(SnippetInk.primary)
        .background {
            ZStack {
                look.tint
                // One hue, lit from above — depth, not a second colour.
                LinearGradient(
                    colors: [.white.opacity(0.10), .black.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                if fullBleedPhoto, let photo = look.photo {
                    photo
                        .resizable()
                        .scaledToFill()
                    // Darker at both ends, where the type sits — the figure
                    // at the top is often over sky.
                    LinearGradient(
                        colors: [.black.opacity(0.42), .black.opacity(0.30), .black.opacity(0.70)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .clipShape(ContainerRelativeShape())
        .environment(\.colorScheme, .dark)
        // Siri already draws snippet text a size up; past this the card
        // outgrows Apple's height and starts to scroll.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

/// What a snippet is drawn in: the trip's colour, made readable, and its
/// photograph when there is one.
struct SnippetLook {
    let tint: Color
    let photo: Image?

    /// The app's own accent — for answers about every trip at once, which
    /// have no one photograph to take a colour from.
    static let brand = SnippetLook(tint: SnippetTint.readable(AppTheme.accent), photo: nil)
}

/// White type, in three strengths. Money direction is carried by words and
/// arrows, never red and green: on a coloured card those two stop reading as
/// "good" and "bad" and start fighting the background.
enum SnippetInk {
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.78)
    static let tertiary = Color.white.opacity(0.58)
    /// Fills for rows, blocks and unselected controls.
    static let wash = Color.white.opacity(0.16)
}

/// Keeps a cover's colour dark enough for white type.
///
/// `CoverTint` lifts a photo's average to a bright, saturated swatch — right
/// for mounting a photo in the app, too light under white text: a beach or a
/// snowfield averages to a pale colour that white disappears into. So the hue
/// and saturation stay and only the brightness comes down, until white on it
/// reaches 4.5:1. Apple asks for more contrast than usual here, because a
/// snippet is often read at arm's length.
enum SnippetTint {
    static func readable(_ color: Color) -> Color {
        let ui = UIColor(color)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard ui.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return color }

        var candidate = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        while contrastWithWhite(candidate) < 4.5, brightness > 0.18 {
            brightness -= 0.03
            candidate = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        }
        return Color(uiColor: candidate)
    }

    private static func contrastWithWhite(_ color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return 21 }
        func linear(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        return 1.05 / (luminance + 0.05)
    }
}

// MARK: - Type

/// The one number the card exists to show.
struct SnippetFigure: View {
    let text: String
    var size: CGFloat = 46

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .contentTransition(.numericText())
    }
}

/// A small label over a group — "Paid by", "Then".
struct SnippetEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(SnippetInk.tertiary)
    }
}

// MARK: - Pieces

/// The trip's name in its own typeface, a line under it, and its photograph
/// as the card's icon.
struct SnippetTripHeader: View {
    let title: String
    let style: TripTitleStyle
    var subtitle: String?
    var photo: Image?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .tripTitle(style, size: 21)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SnippetInk.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let photo {
                SnippetThumbnail(photo: photo, size: 44)
            }
        }
    }
}

/// The trip photo as an icon, ringed so it holds its edge on any colour.
struct SnippetThumbnail: View {
    let photo: Image
    var size: CGFloat = 44

    var body: some View {
        photo
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.27, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
    }
}

/// A traveller's face. The bundled artwork only: an uploaded photo would need
/// a download the card can't wait for, and `AsyncImage` doesn't load inside a
/// snippet, which the system draws rather than the app.
struct SnippetAvatar: View {
    let asset: String
    var size: CGFloat = 28

    var body: some View {
        Image(Traveller.artwork(for: asset))
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.circle)
            .overlay { Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5) }
    }
}

/// The app's dashed timeline card, in white on the trip's colour — the
/// booking the card is about.
struct SnippetEventBlock<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SnippetInk.wash, in: .rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
    }
}

/// Days as dots: filled for the ones that count, hollow for the rest, and a
/// ring on today.
struct SnippetDotGrid: View {
    let total: Int
    let filled: Int
    /// The dot to ring, zero-based; nil for none.
    var marked: Int?
    var columns = 7
    var dot: CGFloat = 10

    var body: some View {
        let rows = Int((Double(max(total, 1)) / Double(columns)).rounded(.up))
        VStack(alignment: .leading, spacing: dot * 0.6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: dot * 0.6) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        if index < total {
                            Circle()
                                .fill(index < filled ? SnippetInk.primary : SnippetInk.wash)
                                .frame(width: dot, height: dot)
                                .overlay {
                                    if index == marked {
                                        Circle()
                                            .strokeBorder(SnippetInk.primary, lineWidth: 1.5)
                                            .frame(width: dot + 6, height: dot + 6)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Controls

/// The two button weights a snippet has, both full capsules at least 44
/// points tall.
///
/// Primary is a white capsule with the label in the trip's colour — the one
/// thing the card suggests doing. Secondary is a translucent white capsule,
/// for everything else. Pressing shrinks and softens the button, the feedback
/// Apple's snippet guidance asks for: the card itself only changes once the
/// action has run and the snippet is drawn again.
struct SnippetButtonStyle: ButtonStyle {
    enum Weight { case primary, secondary }

    var weight: Weight = .primary
    var tint: Color
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 15 : 17, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, compact ? 14 : 16)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 34 : 44)
            .foregroundStyle(weight == .primary ? tint : SnippetInk.primary)
            .background(weight == .primary ? Color.white : Color.white.opacity(0.22), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .blur(radius: configuration.isPressed ? 0.8 : 0)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// A choice among a few — a payer, a split. Selected reads as the primary
/// button does, so the card's one white shape is always the current answer.
struct SnippetChipStyle: ButtonStyle {
    var isSelected: Bool
    var tint: Color
    /// A face with no name — a round chip, padded evenly.
    var iconOnly = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Fixed, not Dynamic Type: Siri already draws its cards large,
            // and a row of choices that truncates is no choice at all.
            .font(.system(size: 15, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, iconOnly ? 6 : 12)
            .frame(minWidth: 36, minHeight: 36)
            .foregroundStyle(isSelected ? tint : SnippetInk.primary)
            .background(isSelected ? Color.white : SnippetInk.wash, in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Formatting

/// The words a card uses for when something happens, shared so Siri's voice
/// and its cards say the same thing.
enum SnippetWhen {
    /// "Today", "Tomorrow", "Sat 14 Sep".
    static func day(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// "2h ago", for how long a claim has been waiting.
    static func ago(_ date: Date) -> String {
        date.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))
    }
}

extension String {
    /// A person's first name, for chips and rows where a surname won't fit.
    var firstName: String {
        split(separator: " ").first.map(String.init) ?? self
    }
}
