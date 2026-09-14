//
//  Layout.swift
//  Equitrip
//

import SwiftUI

// MARK: - Pane metrics

/// What the app knows about the room it has been given.
///
/// Every adaptive decision in the app reads from one of these rather than
/// asking `UIDevice` what kind of machine this is. The distinction matters on
/// iPad: an app in Split View on a 13" iPad has exactly as much width as an
/// iPhone and should lay out like one, while the same app full-screen in
/// landscape has three times the room and should use all of it. The device is
/// the same in both cases; only the pane changed.
///
/// Measured once at the root — see `PaneReader` — and handed down through the
/// environment, so a card buried six views deep can size itself without a
/// `GeometryReader` of its own.
struct PaneMetrics: Equatable {
    /// The width the app actually occupies, safe areas included.
    var width: CGFloat = 393
    var height: CGFloat = 852
    /// Read alongside the width, and required to agree with it: an iPad app
    /// narrowed into Split View keeps a wide-looking window but reports a
    /// compact size class, and it's the size class that's telling the truth
    /// about how much room the *app* has.
    var sizeClass: UserInterfaceSizeClass? = .compact

    // MARK: Breakpoints

    /// Wide enough that a single centred column would leave the page looking
    /// like a phone screenshot pasted onto a desk.
    ///
    /// 700pt rather than a device check: that's an iPad in a two-thirds Split
    /// View, the narrowest arrangement where a rail plus content still leaves
    /// both halves readable.
    static let regularWidth: CGFloat = 700
    /// Full-screen iPad, either orientation — the point at which a screen can
    /// afford two real columns side by side.
    static let wideWidth: CGFloat = 1000

    /// A regular-width pane: two columns are possible, a sidebar is not.
    var isRegular: Bool { width >= Self.regularWidth && sizeClass != .compact }

    /// A full-width iPad. Two columns, a rail, a three-up grid.
    var isWide: Bool { width >= Self.wideWidth && sizeClass != .compact }

    // MARK: Tokens

    /// The page margin. Everything aligned to the screen edge uses this rather
    /// than a literal 20, so widening the pane widens the margin with it and
    /// content never ends up hard against a 13" bezel.
    var gutter: CGFloat {
        if isWide { return 34 }
        if isRegular { return 28 }
        return 20
    }

    /// Vertical rhythm between sections.
    ///
    /// Takes the screen's own phone-tuned gap and opens it up on a wider pane:
    /// the same 26pt that separates two cards on a phone reads as a crease
    /// when the cards either side of it are twice as wide. Expressed as an
    /// adjustment to a base rather than as a single number, so a screen that
    /// was deliberately tighter than its neighbours stays tighter.
    func spacing(_ base: CGFloat) -> CGFloat {
        isRegular ? base + 4 : base
    }

    /// The app's usual section gap, for callers with no opinion of their own.
    var sectionSpacing: CGFloat { spacing(26) }

    /// The gap between the two columns of a split page.
    var columnSpacing: CGFloat { isWide ? 26 : 22 }

    /// How wide a single-column page is allowed to grow before it stops.
    ///
    /// Uncapped on a phone, because the phone *is* the cap. On iPad the cap is
    /// what stops a balance card becoming a 1300pt-wide strip with a number
    /// stranded at one end and a caption at the other.
    var pageWidth: CGFloat {
        if isWide { return 1180 }
        // Deliberately well short of an 11" iPad's 834pt portrait width. A cap
        // that lands within a few points of the screen is the same as no cap:
        // it leaves a margin too small to read as a margin, and the measure it
        // was meant to fix is still a measure nobody can read comfortably.
        if isRegular { return 780 }
        return .infinity
    }

    /// Narrower still, for pages that are mostly prose or a form: a sign-in
    /// sheet, a review step, a chat transcript. Long lines are harder to read
    /// than short ones however much room there is.
    var readableWidth: CGFloat {
        isRegular ? 660 : .infinity
    }

    /// The fixed side rail a detail screen puts its identity in — the trip
    /// photograph and its figures, the settle summary. Only ever used when
    /// `isWide`, so it needn't degrade.
    var railWidth: CGFloat {
        width >= 1250 ? 400 : 348
    }

    /// What a page actually has to lay out in: its cap, minus its margins.
    ///
    /// Computed rather than measured. Every page that needs it applies
    /// `gutter()` and `pageWidth()` in that order, so the answer is already
    /// determined by the pane — and a column width derived from it can be
    /// stated outright instead of arriving a frame late.
    var contentWidth: CGFloat {
        max(0, min(pageWidth, width) - gutter * 2)
    }

    /// A wider rail, for a column of figures rather than a photograph.
    ///
    /// A trip's cover reads fine at 348pt; two currency amounts side by side
    /// with a rule between them do not — at that width one of them wraps or
    /// shrinks, and a balance you have to squint at is the one thing this app
    /// must never produce.
    var figureRailWidth: CGFloat {
        width >= 1250 ? 440 : 398
    }

    /// What's left for the detail column once a rail has taken its share.
    ///
    /// Stated explicitly because `maxWidth: .infinity` is not a cap: a column
    /// whose content has a large minimum width will happily claim more than
    /// the row has and push its neighbour off the screen, which is exactly
    /// what a timeline of long booking titles does to a rail.
    func detailWidth(beside rail: CGFloat) -> CGFloat {
        max(320, contentWidth - rail - columnSpacing)
    }

    var detailWidth: CGFloat { detailWidth(beside: railWidth) }

    /// Columns for a grid of trip cards.
    var tripColumns: Int {
        if width >= 1280 { return 3 }
        if isRegular { return 2 }
        return 1
    }

    /// Cards get a little more rounding as they get bigger, so the corner stays
    /// proportional to the card rather than shrinking into it.
    func corner(_ base: CGFloat) -> CGFloat {
        isRegular ? base + 4 : base
    }

    /// Scales a hand-tuned phone dimension up for a wider pane.
    ///
    /// Deliberately blunt, and deliberately not applied to type: photographs,
    /// hero heights and avatar clusters want to grow with the page, while a
    /// 13pt caption is 13pt on every screen ever made. Anywhere the phone
    /// number is already right, this is simply not called.
    func scaled(_ value: CGFloat, wide: CGFloat? = nil, regular: CGFloat? = nil) -> CGFloat {
        if isWide, let wide { return wide }
        if isRegular, let regular { return regular }
        return value
    }
}

extension EnvironmentValues {
    /// The room the app has, as measured at the root. Defaults to an iPhone
    /// shape so a preview or a detached view lays out like a phone rather than
    /// like nothing.
    @Entry var pane = PaneMetrics()
}

// MARK: - Reader

/// Measures the app's own window and publishes it as `\.pane`.
///
/// Wrapped around the whole app rather than sprinkled per screen: sheets and
/// covers inherit the environment from whatever presented them, so a single
/// measurement reaches every screen in the app, the modal ones included.
///
/// `onGeometryChange` rather than a `GeometryReader` wrapper: the reader would
/// flatten the view it contains into a top-leading stack, which is exactly the
/// kind of silent layout change you don't want at the root of an app.
///
/// One consequence worth knowing: inside a `.sheet` on iPad, `\.pane` still
/// describes the *window*, not the 540pt form sheet the content is actually
/// in. That's deliberate — every screen that branches on the pane is a
/// full-window screen, and the sheets are all phone-shaped forms that want the
/// phone layout anyway. A sheet that ever needs to lay itself out adaptively
/// should wrap its own body in another `PaneReader` rather than trusting the
/// value it inherits.
struct PaneReader<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ViewBuilder var content: Content

    @State private var size: CGSize = .zero

    var body: some View {
        content
            .environment(\.pane, metrics)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                size = newValue
            }
    }

    private var metrics: PaneMetrics {
        guard size.width > 0 else {
            return PaneMetrics(sizeClass: sizeClass)
        }
        return PaneMetrics(width: size.width, height: size.height, sizeClass: sizeClass)
    }
}

// MARK: - Page width

/// Caps a page's content and centres what's left.
///
/// The single most load-bearing modifier in the iPad pass. Screens are built
/// as one column with 20pt margins, which is correct on a phone and absurd at
/// 1366pt — a line of body text three feet long, a row whose avatar and its
/// caption are separated by half a metre of nothing. Capping restores the
/// measure; centring is what makes the remaining margin read as deliberate
/// space rather than as the app failing to fill the window.
private struct PageWidth: ViewModifier {
    @Environment(\.pane) private var pane

    /// Nil takes the pane's own page width; a screen that wants the narrower
    /// prose measure passes `pane.readableWidth`.
    var limit: CGFloat?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: limit ?? pane.pageWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Caps this view at the pane's page width and centres it.
    func pageWidth(_ limit: CGFloat? = nil) -> some View {
        modifier(PageWidth(limit: limit))
    }

    /// The prose measure — forms, transcripts, single-question steps.
    ///
    /// `unless` turns it off for one branch of a screen that otherwise wants
    /// it: a camera feed or a map in the middle of a wizard is the exception
    /// that should still fill the window.
    func readableWidth(unless disabled: Bool = false) -> some View {
        modifier(ReadableWidth(disabled: disabled))
    }

    /// The page margin for this pane, applied horizontally.
    func gutter() -> some View {
        modifier(Gutter())
    }
}

private struct ReadableWidth: ViewModifier {
    @Environment(\.pane) private var pane

    var disabled = false

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: disabled ? .infinity : pane.readableWidth)
            .frame(maxWidth: .infinity)
    }
}

private struct Gutter: ViewModifier {
    @Environment(\.pane) private var pane

    func body(content: Content) -> some View {
        content.padding(.horizontal, pane.gutter)
    }
}

// MARK: - Top tab bar

/// A fixed header that shares its line with the iPad's floating tab bar.
///
/// On iPad the tab bar sits at the top of the window and adds its height to
/// every screen's safe area, so a header placed in the safe area lands a whole
/// tab bar below it — a band of empty canvas with the tabs floating above.
/// The tabs only take the centre of that line, so a title on the left and
/// buttons on the right can share it.
///
/// Laid out as an overlay that ignores the top safe area rather than as a
/// safe-area bar pulled up with negative padding: a bar's content drawn above
/// its own frame still *looks* right but stops receiving taps. The scroll
/// content is pushed down to clear the header with `safeAreaPadding`. Where
/// there's no top tab bar (a phone) it's an ordinary safe-area bar.
private struct TabAlignedHeader<Header: View>: ViewModifier {
    var header: Header

    /// The safe area as the screen sees it — status bar plus any tab bar.
    @State private var viewInset: CGFloat = 0
    @State private var headerHeight: CGFloat = 0

    private var tabBar: CGFloat { viewInset - windowInset }
    private var hasTopTabBar: Bool { tabBar > 1 }

    /// Where the header's frame starts, measured from the top of the window.
    /// The bar's centre sits 30pt under the status bar; the headers' own
    /// paddings (4 above, 10 below) put their visual centre 3pt above their
    /// frame's, hence 27 rather than 30.
    private var headerTop: CGFloat { windowInset + 27 - headerHeight / 2 }

    func body(content: Content) -> some View {
        content
            .safeAreaBar(edge: .top, spacing: 0) {
                if !hasTopTabBar { header }
            }
            .safeAreaPadding(.top, hasTopTabBar ? max(0, headerTop + headerHeight - viewInset) : 0)
            .overlay(alignment: .top) {
                if hasTopTabBar {
                    header
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                        .padding(.top, headerTop)
                        .ignoresSafeArea(.container, edges: .top)
                }
            }
            // Measured outside the padding above, so the padding can't feed
            // back into the inset it was computed from.
            .background {
                Color.clear
                    .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { viewInset = $0 }
            }
    }

    /// The window's own inset: the status bar, without the tab bar's share.
    private var windowInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? viewInset
    }
}

extension View {
    /// A fixed top header, in line with the iPad's floating tab bar when there
    /// is one and an ordinary safe-area bar when there isn't.
    func tabAlignedHeader<Header: View>(@ViewBuilder _ header: () -> Header) -> some View {
        modifier(TabAlignedHeader(header: header()))
    }
}

// MARK: - Two columns

/// Two stacks side by side when there's room, one on top of the other when
/// there isn't.
///
/// The ratio is expressed as the leading column's share rather than as two
/// widths, so the pair always fills the page exactly and a resize — rotating,
/// dragging a Split View divider — moves both halves together.
///
/// Top-aligned on purpose. The two columns hold unrelated numbers of cards and
/// always will; centring them vertically would make the shorter one float in
/// the middle of a gap, which reads as a layout mistake rather than as a
/// column that simply had less to say.
struct AdaptiveColumns<Leading: View, Trailing: View>: View {
    @Environment(\.pane) private var pane

    /// The leading column's share of the width, 0–1.
    var ratio: Double = 0.56
    /// Below this the columns stack. Defaults to the pane's own wide
    /// breakpoint; a page whose two halves are both narrow can lower it.
    var breakpoint: CGFloat = PaneMetrics.wideWidth
    /// Spacing when stacked — matched to the page's own section rhythm.
    var stackSpacing: CGFloat?

    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    /// The row's measured width. Seeded from the pane rather than left at zero
    /// so the first frame is already close to right — a column that starts at
    /// its intrinsic width and snaps to its share one frame later is a visible
    /// flinch on every appearance.
    @State private var measured: CGFloat?

    private var side: Bool {
        pane.width >= breakpoint && pane.sizeClass != .compact
    }

    private var rowWidth: CGFloat {
        measured ?? max(0, min(pane.pageWidth, pane.width) - pane.gutter * 2)
    }

    var body: some View {
        Group {
            if side {
                let usable = max(0, rowWidth - pane.columnSpacing)

                HStack(alignment: .top, spacing: pane.columnSpacing) {
                    leading
                        .frame(width: usable > 0 ? usable * ratio : nil)

                    trailing
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                VStack(alignment: .leading, spacing: stackSpacing ?? pane.sectionSpacing) {
                    leading
                    trailing
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { measured = $0 }
    }
}

// MARK: - Card grid

/// An even grid of cards, and a plain stack when there's only room for one.
///
/// Built on `LazyVGrid` so a long portfolio of photo-backed trip cards still
/// only decodes what's on screen — the reason the phone list is lazy in the
/// first place, and doubly true when three of them fit across.
struct CardGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    var items: Data
    /// How many across. Usually `pane.tripColumns`; a page with denser cards
    /// can ask for more.
    var columns: Int
    var spacing: CGFloat = 16
    @ViewBuilder var content: (Data.Element) -> Content

    var body: some View {
        if columns <= 1 {
            VStack(spacing: spacing) {
                ForEach(items) { content($0) }
            }
        } else {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: spacing, alignment: .top),
                    count: columns
                ),
                spacing: spacing
            ) {
                ForEach(items) { content($0) }
            }
        }
    }
}
