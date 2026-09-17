//
//  Buttons.swift
//  Equitrip
//

import SwiftUI

// MARK: - Buttons

/// Slight give on tap so buttons feel physical.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The filled, high-contrast action button used once per screen.
struct PrimaryButton: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    var systemImage: String? = "arrow.right"
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            ZStack {
                // Kept in the layout while loading so the button never resizes.
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .opacity(isLoading ? 0 : 1)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.ctaLabel)
                    .opacity(isLoading ? 1 : 0)
            }
            .foregroundStyle(AppTheme.ctaLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.cta, in: .rect(cornerRadius: 18))
            .shadow(color: AppTheme.softShadow(scheme), radius: 18, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(.easeOut(duration: 0.2), value: isLoading)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

/// Low-emphasis text action.
struct TextButton: View {
    let title: String
    var emphasis: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let emphasis {
                    Text("\(title) \(Text(emphasis).foregroundColor(AppTheme.accent).bold())")
                } else {
                    Text(title)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppTheme.inkSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Circular glyph button

/// Glass circle carrying a single SF Symbol — the top-bar affordance.
struct CircleGlyphButton: View {
    let symbol: String
    var size: CGFloat = 44
    var action: () -> Void

    var body: some View {
        GlassCircleButton(size: size, action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}

/// The notifications bell.
///
/// Uses SF Symbols' own `bell.badge` rather than a hand-drawn count bubble:
/// the badge is part of the glyph, so it sits where Apple puts it, scales with
/// the symbol and never gets clipped by the circle around it.
struct NotificationBellButton: View {
    var unread: Int
    var size: CGFloat = 50
    let action: () -> Void

    var body: some View {
        GlassCircleButton(size: size, action: action) {
            Image(systemName: unread > 0 ? "bell.badge" : "bell")
                .font(.system(size: size * 0.38, weight: .medium))
                .symbolRenderingMode(unread > 0 ? .palette : .monochrome)
                .foregroundStyle(
                    unread > 0 ? AppTheme.danger : AppTheme.ink,
                    AppTheme.ink
                )
        }
        .accessibilityLabel(unread > 0 ? "Notifications, \(unread) unread" : "Notifications")
    }
}

// MARK: - Glass chrome

/// Circular Liquid Glass control. The whole navigation layer of the app is
/// built from these, so the chrome reads as one material and the content
/// cards below stay opaque.
struct GlassCircleButton<Content: View>: View {
    var size: CGFloat = 44
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            content
                .frame(width: size, height: size)
                // Without this the tap target is the glyph's own pixels, not
                // the circle it appears to be.
                .contentShape(.circle)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
    }
}
