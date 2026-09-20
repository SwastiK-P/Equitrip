//
//  TripCoverCard.swift
//  Equitrip
//

import SwiftUI

/// The trip as an object you can touch: its photograph, its name and where
/// it's going, in one card.
///
/// The creation flow used to draw this twice over — a read-only preview at the
/// top of a form, then a `Trip name` field and a `Destination` row underneath
/// repeating what the preview had just shown. The same two facts appeared
/// three times on one screen and only one of the three copies could be
/// changed. Here the card is the control: the name is edited where it's read,
/// the destination opens the search, the photograph changes in place. The
/// review step draws the same card, so what you name on the way in is the
/// thing you check on the way out.
struct TripCoverCard: View {
    @Binding var draft: TripDraft

    var height: CGFloat = 200
    /// Off on the step that hasn't asked about dates yet — "4 days" is a
    /// default nobody has agreed to at that point, and stating it as fact is
    /// how a default becomes a decision.
    var showsDayCount: Bool = true
    var onChangePhoto: () -> Void
    var onChangeDestination: () -> Void
    /// Held by the caller so a screen can put the cursor in the name itself —
    /// the Continue button on the first step does exactly that when the trip
    /// still hasn't got one.
    @Binding var isEditingTitle: Bool

    @FocusState private var titleFocused: Bool

    var body: some View {
        DestinationImage(
            query: draft.destination.count >= 3 ? draft.destination : nil,
            photo: draft.cover,
            fallbackSymbol: draft.inferredSymbol,
            fallbackTint: draft.inferredTint,
            onResolve: { draft.cover = $0 }
        )
        .frame(height: height)
        .frame(maxWidth: .infinity)
        // The scrim goes on before anything that has to be read against it.
        // The other way round — which is how the review screen had it — draws
        // a black gradient over the trip's own name, and the one word on the
        // screen that has to be legible is the one wearing a grey wash.
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.68)], startPoint: .top, endPoint: .bottom)
                .frame(height: height * 0.66)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) { badge }
        .overlay(alignment: .topTrailing) { photoButton }
        .overlay(alignment: .bottomLeading) { identity }
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
        .shadow(color: AppTheme.softShadow(.light), radius: 14, y: 6)
        .animation(.easeOut(duration: 0.3), value: draft.cover)
        .animation(.easeOut(duration: 0.25), value: draft.inferredSymbol)
        .onChange(of: titleFocused) { _, focused in
            if !focused { isEditingTitle = false }
        }
        // The caller can switch this on from outside, at which point the
        // field exists and can take the cursor.
        .onChange(of: isEditingTitle) { _, editing in
            if editing { titleFocused = true }
        }
    }

    // MARK: - Badge

    @ViewBuilder
    private var badge: some View {
        if showsDayCount {
            HStack(spacing: 6) {
                Image(systemName: draft.inferredSymbol)
                    .font(.system(size: 11, weight: .bold))
                Text(draft.dayCount.pluralised("day"))
                    .font(.system(size: 11.5, weight: .semibold))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.28), in: .capsule)
            .background(.ultraThinMaterial, in: .capsule)
            .padding(14)
        }
    }

    private var photoButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onChangePhoto()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 11, weight: .semibold))
                Text("Change")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.42), in: .capsule)
            .padding(14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change cover photo")
    }

    // MARK: - Name and place

    private var identity: some View {
        VStack(alignment: .leading, spacing: 8) {
            title
            destination
        }
        .padding(16)
    }

    /// Tapped, the name becomes a field where it stands.
    ///
    /// The pencil is there because a heading that happens to be editable looks
    /// exactly like a heading that isn't — and this one is the only required
    /// field in the whole flow.
    @ViewBuilder
    private var title: some View {
        if isEditingTitle {
            TextField(
                "",
                text: $draft.title,
                // The system's placeholder colour is a dark grey meant for a
                // white field. On a photograph it disappears, which is how a
                // field with a prompt ends up looking like a field that's
                // broken.
                prompt: Text("Name this trip").foregroundStyle(.white.opacity(0.6))
            )
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .tint(.white)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .focused($titleFocused)
            .onSubmit { isEditingTitle = false }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Button(action: edit) {
                HStack(spacing: 9) {
                    Text(draft.title.isEmpty ? "Name this trip" : draft.title)
                        .tripTitle(draft.titleStyle, size: 25)
                        .foregroundStyle(.white.opacity(draft.title.isEmpty ? 0.72 : 1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .shadow(color: .black.opacity(0.45), radius: 6, y: 1)

                    Image(systemName: "pencil")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.black.opacity(0.36), in: .circle)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(draft.title.isEmpty ? "Name this trip" : "Trip name, \(draft.title)")
            .accessibilityHint("Opens the name for editing")
        }
    }

    private var destination: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onChangeDestination()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 10.5, weight: .bold))

                Text(draft.destination.isEmpty ? "Add a destination" : draft.destination)
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.75)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.36), in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private func edit() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isEditingTitle = true
        titleFocused = true
    }
}
