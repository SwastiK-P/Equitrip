//
//  ChatChecklistComposer.swift
//  Equitrip
//

import SwiftUI

/// Starting a bring-list: the things the group needs, before anyone has said
/// they've got them.
struct ChatChecklistComposer: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    var onSend: (ChatAttachment) -> Void

    @State private var title = ""
    @State private var items: [ChatAttachment.Option] = []
    @State private var entry = ""
    @FocusState private var entryFocused: Bool

    private static let maxItems = 20

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "New bring list", caption: "People tick what they've got covered.")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassField(label: "Title", placeholder: defaultTitle, text: $title, autocapitalisation: .sentences)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Items")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkSecondary)

                        if !items.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(items) { item in
                                    HStack(spacing: 10) {
                                        Image(systemName: "square")
                                            .foregroundStyle(AppTheme.inkTertiary)
                                        Text(item.text)
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppTheme.ink)
                                        Spacer(minLength: 6)
                                        Button {
                                            withAnimation(.snappy) { items.removeAll { $0.id == item.id } }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 17))
                                                .foregroundStyle(AppTheme.inkTertiary)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Remove \(item.text)")
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)

                                    if item.id != items.last?.id { Hairline(inset: 14) }
                                }
                            }
                            .panelSurface(corner: 16)
                        }

                        if items.count < Self.maxItems {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                                TextField("Add an item", text: $entry)
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppTheme.ink)
                                    .focused($entryFocused)
                                    .submitLabel(.done)
                                    .onSubmit { add(entry, keepFocus: true) }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .panelSurface(corner: 14)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ideas")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkSecondary)

                        FlowLayout(spacing: 8) {
                            ForEach(ideas, id: \.self) { idea in
                                Button { add(idea, keepFocus: false) } label: {
                                    Label(idea, systemImage: "plus")
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundStyle(AppTheme.inkSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.card, in: .capsule)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: "Send list", systemImage: nil, isEnabled: !pendingItems.isEmpty) {
                let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                onSend(.checklist(.init(title: name.isEmpty ? defaultTitle : name, items: pendingItems)))
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var defaultTitle: String { "What to bring to \(trip.destination.split(separator: ",").first.map(String.init) ?? "the trip")" }

    /// What's been added, plus whatever is still sitting in the entry field —
    /// typing the last item and tapping Send without pressing return first
    /// shouldn't lose it.
    private var pendingItems: [ChatAttachment.Option] {
        let typed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        return typed.isEmpty ? items : items + [.init(text: typed)]
    }

    /// Things groups forget, minus anything already on the list.
    private var ideas: [String] {
        let base = ["Sunscreen", "Chargers", "Power bank", "Speaker", "First-aid kit", "Snacks", "Umbrella", "Cards", "Adapters", "Water bottles"]
        let taken = Set(items.map { $0.text.lowercased() })
        return base.filter { !taken.contains($0.lowercased()) }
    }

    private func add(_ text: String, keepFocus: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, items.count < Self.maxItems,
              !items.contains(where: { $0.text.caseInsensitiveCompare(trimmed) == .orderedSame })
        else { return }

        withAnimation(.snappy) { items.append(.init(text: trimmed)) }
        if text == entry { entry = "" }
        if keepFocus { entryFocused = true }
    }
}
