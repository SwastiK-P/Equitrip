//
//  TwinPanel.swift
//  Equitrip
//

import SwiftUI

/// A sheet that lives on top of a map without being a presentation: three
/// resting heights, dragged by its grabber, the map still pannable above it.
///
/// Not a `.sheet`: a real sheet over a full-screen cover fights the cover's
/// dismissal and can't sit beside the map on iPad. This is chrome, the way
/// Maps' own card is — so it's drawn in place, and on a wide window it stops
/// being a sheet and becomes a floating column instead.
struct TwinPanel<Header: View, Content: View>: View {
    typealias Detent = TwinPanelDetent

    @Binding var detent: Detent
    /// Changing it scrolls the content back to the top — a mode switch
    /// shouldn't open the new page at the old page's scroll offset.
    var resetKey: AnyHashable = 0
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    @Environment(\.pane) private var pane
    @GestureState private var drag: CGFloat = 0
    @State private var position = ScrollPosition(edge: .top)

    var body: some View {
        GeometryReader { proxy in
            let total = proxy.size.height
            if pane.isWide {
                column(height: total)
            } else {
                sheet(total: total, width: proxy.size.width)
            }
        }
        .onChange(of: resetKey) { _, _ in position.scrollTo(edge: .top) }
    }

    /// Laid out once at its tallest and slid, never resized: changing the
    /// height on every frame of a drag re-laid out the whole scroll view —
    /// animated skies, dials, the booking list — sixty times a second, and
    /// the panel stuttered its way up. An offset is only a move.
    private func sheet(total: CGFloat, width: CGFloat) -> some View {
        let tallest = Detent.full.height(in: total)
        let height = max(160, min(total * 0.95, detent.height(in: total) - drag))
        // Whatever sits below the screen at this detent, as scroll space at
        // the end so the last card can still come up into view.
        let hidden = tallest - detent.height(in: total)

        return VStack(spacing: 0) {
            VStack(spacing: 4) {
                // Tapping cycles the height from the grabber only: on the
                // whole header it also fired under the mode picker's taps.
                Capsule()
                    .fill(AppTheme.inkTertiary.opacity(0.35))
                    .frame(width: 38, height: 5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            detent = detent == .peek ? .half : detent == .half ? .full : .half
                        }
                    }
                    .accessibilityLabel("Resize panel")
                    .accessibilityAddTraits(.isButton)
                header()
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
            .gesture(dragGesture(total: total))

            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    content()
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 40 + max(0, hidden))
                        // Exactly the panel's width: a card wider than it let the
                        // whole list be pushed sideways. An explicit width, not
                        // `containerRelativeFrame` — on iPad that resolved against
                        // the window and drew every card window-wide.
                        .frame(width: width)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .scrollPosition($position)
                .scrollDisabled(detent == .peek)
                .agentScroller("twin.scroll") { proxy.scrollTo($0, anchor: .center) }
            }
        }
        .frame(height: tallest, alignment: .top)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
                .fill(AppTheme.canvasTop)
                .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous))
        .offset(y: tallest - height)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }

    /// A full-height sidebar under the top bar, the way Maps sits on iPad.
    private func column(height: CGFloat) -> some View {
        let width = pane.twinColumnWidth
        return VStack(spacing: 0) {
            header().padding(.top, 14)
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    content()
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                        .frame(width: width)
                }
                .scrollIndicators(.hidden)
                .scrollPosition($position)
                .agentScroller("twin.scroll") { proxy.scrollTo($0, anchor: .center) }
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppTheme.canvasTop, in: .rect(cornerRadius: 30, style: .continuous))
        .clipShape(.rect(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 24, y: 8)
        .padding(.leading, PaneMetrics.twinColumnInset)
        .padding(.top, PaneMetrics.twinColumnTop)
        .padding(.bottom, PaneMetrics.twinColumnInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func dragGesture(total: CGFloat) -> some Gesture {
        // Global: the panel moves under the finger, and a translation measured
        // in its own moving space fed back into itself and jittered.
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .updating($drag) { value, state, _ in state = value.translation.height }
            .onEnded { value in
                let projected = detent.height(in: total) - value.predictedEndTranslation.height
                let nearest = Detent.allCases.min {
                    abs($0.height(in: total) - projected) < abs($1.height(in: total) - projected)
                } ?? .half
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { detent = nearest }
            }
    }
}

/// Where the twin's panel rests on a phone.
enum TwinPanelDetent: CaseIterable {
    case peek, half, full

    func height(in total: CGFloat) -> CGFloat {
        switch self {
        case .peek: min(300, total * 0.36)
        case .half: total * 0.58
        case .full: total * 0.92
        }
    }
}

/// Where the twin's panel sits on a wide window, shared with the screen so
/// the top bar, callout and map framing leave room for it.
extension PaneMetrics {
    /// Wider on a big iPad so the cards' figures don't wrap, never more than
    /// about a third of the window so the map stays the subject.
    var twinColumnWidth: CGFloat { min(460, max(380, width * 0.36)) }
    static let twinColumnInset: CGFloat = 18
    /// Clears the floating top bar.
    static let twinColumnTop: CGFloat = 66
    /// How much of the window's width the column covers, gutters included.
    var twinColumnFootprint: CGFloat { twinColumnWidth + Self.twinColumnInset * 2 }
}
