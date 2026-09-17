//
//  ChatDetailsSheet.swift
//  Equitrip
//

import SwiftUI

/// Everything worth finding again in a trip's thread: search, what's pinned,
/// the photos, the places, and the open questions.
///
/// Three days into a trip the answer to "what was the Airbnb door code?" is
/// four hundred messages up. Shelving the thread by kind is what turns the
/// chat from a scroll into a reference.
struct ChatDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let chat: ChatService
    let trip: Trip
    var onJump: (UUID) -> Void
    var onOpenPhoto: (URL, ChatMessage) -> Void

    enum Shelf: String, CaseIterable, Identifiable {
        case pinned = "Pinned"
        case photos = "Photos"
        case places = "Places"
        case plans = "Plans"

        var id: String { rawValue }
    }

    @State private var shelf: Shelf
    @State private var query = ""

    init(chat: ChatService, trip: Trip, startOn shelf: Shelf = .pinned, onJump: @escaping (UUID) -> Void, onOpenPhoto: @escaping (URL, ChatMessage) -> Void) {
        self.chat = chat
        self.trip = trip
        self.onJump = onJump
        self.onOpenPhoto = onOpenPhoto
        _shelf = State(initialValue: shelf)
    }

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: trip.title, caption: "\(trip.dateRange) · \(chat.messages.filter { !$0.isDeleted }.count.pluralised("message"))")

            VStack(spacing: 12) {
                searchField

                if query.isEmpty {
                    Picker("Shelf", selection: $shelf) {
                        ForEach(Shelf.allCases) { shelf in
                            Text(shelf.rawValue).tag(shelf)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ScrollView {
                Group {
                    if !query.isEmpty {
                        messageList(chat.search(query), empty: "Nothing in the chat matches \"\(query)\"")
                    } else {
                        switch shelf {
                        case .pinned:
                            messageList(chat.pinnedMessages, empty: "Nothing pinned yet. Long-press a message to pin it — door codes, ferry times, the wifi.")
                        case .photos:
                            photoGrid
                        case .places:
                            messageList(messages(where: { if case .place = $0 { true } else { false } }), empty: "No places shared yet.")
                        case .plans:
                            messageList(messages(where: \.takesResponses), empty: "No polls, meetups or bring lists yet.")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            TextField("Search the chat", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .panelSurface(corner: 14)
    }

    private func messages(where predicate: (ChatAttachment) -> Bool) -> [ChatMessage] {
        chat.messages
            .filter { message in !message.isDeleted && message.attachment.map(predicate) == true }
            .reversed()
    }

    @ViewBuilder
    private func messageList(_ messages: [ChatMessage], empty: String) -> some View {
        if messages.isEmpty {
            Text(empty)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
                .padding(.horizontal, 20)
        } else {
            VStack(spacing: 0) {
                ForEach(messages) { message in
                    Button {
                        dismiss()
                        onJump(message.id)
                    } label: {
                        row(message)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if message.id != messages.last?.id { Hairline(inset: 54) }
                }
            }
            .cardSurface(corner: 18, shadow: 4)
        }
    }

    private func row(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 11) {
            if let author = chat.author(of: message) {
                TravellerAvatar(traveller: author, size: 30)
            } else {
                Circle().fill(AppTheme.inkTertiary.opacity(0.2)).frame(width: 30, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(chat.authorName(of: message))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer(minLength: 6)
                    Text(dateLabel(message.sentAt))
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                Text(highlighted(message.preview))
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(.rect)
    }

    /// The search term, set in bold where it appears.
    private func highlighted(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        guard !query.isEmpty, let range = result.range(of: query, options: .caseInsensitive) else { return result }
        result[range].font = .system(size: 14, weight: .bold)
        result[range].foregroundColor = AppTheme.ink
        return result
    }

    private func dateLabel(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? DateFormatter.cached("h:mm a").string(from: date)
            : DateFormatter.cached("d MMM").string(from: date)
    }

    @ViewBuilder
    private var photoGrid: some View {
        let photos: [(ChatMessage, ChatAttachment.Photo)] = chat.messages.reversed().compactMap { message in
            guard !message.isDeleted, message.delivery == .sent, case .photo(let photo) = message.attachment else { return nil }
            return (message, photo)
        }

        if photos.isEmpty {
            Text("No photos shared yet.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(photos, id: \.0.id) { message, photo in
                    Button { onOpenPhoto(photo.url, message) } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                ChatRemoteImage(url: photo.url)
                            }
                            .clipShape(.rect(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .contextMenu {
                        Button("Show in chat", systemImage: "text.bubble") {
                            dismiss()
                            onJump(message.id)
                        }
                        ShareLink(item: photo.url)
                    }
                }
            }
        }
    }
}
