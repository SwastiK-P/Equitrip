//
//  AvatarPickerSheet.swift
//  Equitrip
//

import PhotosUI
import SwiftUI

/// Choosing the face you show up as.
///
/// Everybody used to be handed a memoji — the same one, `MemojiChris`, for
/// every account on the device — which made the avatar decoration rather than
/// identification: four people on a trip, four identical faces. Two ways out
/// of that, in the order people reach for them: a photograph of yourself, or
/// one of the memoji if you'd rather not put a photo in a shared ledger.
///
/// They're exclusive, not layered. Choosing a photo replaces the memoji
/// rather than sitting in front of it — the grid disappears the moment one is
/// picked, and the memoji is gone from the saved avatar, not just hidden
/// behind it.
struct AvatarPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Called once the new face is saved, so the presenting screen can redraw.
    var onSaved: () -> Void = {}

    @State private var asset = CurrentUser.traveller.asset
    @State private var photoURL = CurrentUser.traveller.avatarURL
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isWorking = false
    @State private var failure: String?

    /// What the sheet is currently proposing, drawn with the real avatar view
    /// so the preview is the thing itself rather than an approximation.
    private var preview: Traveller {
        Traveller(id: Traveller.you.id, name: CurrentUser.traveller.name, asset: asset, avatarURL: photoURL)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    MemojiAvatar(traveller: preview, size: 104)
                        .padding(.top, 6)

                    photoRow

                    if photoURL == nil { memojiGrid }

                    if let failure {
                        Label(failure, systemImage: "exclamationmark.circle")
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.danger)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) { saveBar }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onChange(of: pickedPhoto) { _, picked in
            guard let picked else { return }
            Task { await upload(picked) }
        }
    }

    private var header: some View {
        HStack {
            Text("Your face")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Photo

    private var photoRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Photo")

            HStack(spacing: 10) {
                PhotosPicker(selection: $pickedPhoto, matching: .images) {
                    HStack(spacing: 10) {
                        if isWorking {
                            ProgressView().controlSize(.small).frame(width: 34, height: 34)
                        } else {
                            SymbolBadge(symbol: "person.crop.square", tint: AppTheme.accent, size: 34)
                        }

                        Text(photoURL == nil ? "Choose a photo" : "Change photo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.ink)

                        Spacer(minLength: 6)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(isWorking)
            }
            .panelSurface(corner: 18)

            if photoURL != nil {
                Button("Use my memoji instead") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { photoURL = nil }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .buttonStyle(.plain)
                .padding(.leading, 2)
            }
        }
    }

    // MARK: - Memoji

    private var memojiGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Memoji")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                spacing: 12
            ) {
                ForEach(Traveller.memoji, id: \.self) { candidate in
                    memojiTile(candidate)
                }
            }
            .padding(14)
            .panelSurface(corner: 20)
        }
    }

    private func memojiTile(_ candidate: String) -> some View {
        let on = asset == candidate

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { asset = candidate }
        } label: {
            Image(candidate)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(.circle)
                .overlay {
                    Circle().strokeBorder(on ? AppTheme.accent : .clear, lineWidth: 2.5)
                }
                .overlay(alignment: .bottomTrailing) {
                    if on {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accent, AppTheme.card)
                            .offset(x: 2, y: 2)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(candidate)
    }

    // MARK: - Saving

    private var saveBar: some View {
        Button(action: save) {
            Text("Save")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(isWorking)
        .opacity(isWorking ? 0.5 : 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func save() {
        isWorking = true
        failure = nil

        Task {
            defer { isWorking = false }
            do {
                try await SupabaseRepository.shared.updateAvatar(asset: asset, url: photoURL)
                // Locally too, and immediately: every `MemojiAvatar` in the app
                // reads `CurrentUser`, and waiting for the next sync would leave
                // the old face on screen behind a sheet that just said "Saved".
                CurrentUser.adoptAvatar(asset: asset, url: photoURL)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onSaved()
                dismiss()
            } catch {
                failure = AuthService.message(for: error)
            }
        }
    }

    @MainActor
    private func upload(_ picked: PhotosPickerItem) async {
        isWorking = true
        failure = nil
        defer {
            isWorking = false
            pickedPhoto = nil
        }

        guard let profile = SupabaseRepository.shared.currentProfileID else {
            failure = "You're not signed in."
            return
        }

        guard let data = try? await picked.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegForUpload(maxDimension: 800) else {
            failure = "Couldn't read that image."
            return
        }

        do {
            photoURL = try await MediaStore.shared.uploadAvatar(jpeg, for: profile)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            failure = (error as? MediaStore.StoreError)?.errorDescription
                ?? AuthService.message(for: error)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(AppTheme.inkTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 2)
    }
}
