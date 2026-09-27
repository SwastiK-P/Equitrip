//
//  EquiAgentCursor.swift
//  Equitrip
//

import SwiftUI

/// Equi's pointer: an arrow with a name tag, the way a collaborator's cursor
/// shows up in a shared document.
///
/// A pointer rather than a floating finger or a dot because it says *someone
/// else is at the controls* in a form everyone has already learned from
/// shared docs — and its tip is an exact point, so it lands visibly on the
/// control it's about to press. The tag names who is driving, and switches
/// to "typing" while a field is being filled.
struct EquiAgentCursor: View {
    var isPressing: Bool
    var isTyping: Bool

    var body: some View {
        // Laid out from the tip: the view's origin *is* the hotspot, and the
        // caller positions that point on the control.
        ZStack(alignment: .topLeading) {
            PointerShape()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accent, Palette.violet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    PointerShape()
                        .stroke(.white, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                }
                .frame(width: 20, height: 25)
                .shadow(color: AppTheme.accent.opacity(0.45), radius: 8, y: 3)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)

            tag
                .offset(x: 17, y: 21)
        }
        .scaleEffect(isPressing ? 0.8 : 1, anchor: .topLeading)
        .frame(width: 140, height: 60, alignment: .topLeading)
    }

    private var tag: some View {
        HStack(spacing: 4) {
            Image("Equi")
                .font(.system(size: 10, weight: .bold))
            Text(isTyping ? "typing" : "Equi")
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .contentTransition(.opacity)
            if isTyping {
                TypingDots()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(
            LinearGradient(colors: [AppTheme.accent, AppTheme.accentDeep], startPoint: .top, endPoint: .bottom),
            in: .capsule
        )
        .overlay { Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 0.75) }
        .shadow(color: AppTheme.accent.opacity(0.3), radius: 6, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isTyping)
    }
}

/// The ring a press leaves where it landed.
struct EquiAgentRipple: View {
    @State private var spread = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accent.opacity(spread ? 0 : 0.22))
                .frame(width: spread ? 70 : 16, height: spread ? 70 : 16)
            Circle()
                .strokeBorder(AppTheme.accent.opacity(spread ? 0 : 0.8), lineWidth: spread ? 1 : 2.5)
                .frame(width: spread ? 58 : 12, height: spread ? 58 : 12)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { spread = true }
        }
    }
}

private struct TypingDots: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 3, height: 3)
                        .opacity(0.35 + 0.65 * max(0, sin(t * 7 - Double(index) * 0.9)))
                }
            }
        }
    }
}

/// A classic arrow pointer, tip at the origin, softened at every corner by
/// the stroke's round joins.
private struct PointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width / 20
        let h = rect.height / 25
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 19.5 * h))
        path.addLine(to: CGPoint(x: 5 * w, y: 15 * h))
        path.addLine(to: CGPoint(x: 8.6 * w, y: 23.4 * h))
        path.addLine(to: CGPoint(x: 12 * w, y: 21.9 * h))
        path.addLine(to: CGPoint(x: 8.4 * w, y: 13.8 * h))
        path.addLine(to: CGPoint(x: 15 * w, y: 13.4 * h))
        path.closeSubpath()
        return path
    }
}
