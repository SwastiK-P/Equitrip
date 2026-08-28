//
//  ProfileSheet.swift
//  Equitrip
//

import SwiftUI

/// What the top-right avatar opens. Identity first, then the numbers that
/// follow you across trips, then settings, then the way out.
struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    var userName: String?
    var onSignOut: () -> Void = {}

    @State private var showAvatarPicker = false
    /// Bumped when the avatar is saved. `CurrentUser` is process-wide state
    /// rather than observable, so nothing here would otherwise notice that the
    /// face changed.
    @State private var avatarVersion = 0

    private var displayName: String {
        guard let userName, !userName.isEmpty else { return "Traveller" }
        return userName.contains("@") ? String(userName.split(separator: "@")[0]).capitalized : userName
    }

    private var handle: String {
        guard let userName, userName.contains("@") else { return "Signed in" }
        return userName
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                identity
                stats
                settings
                signOut
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet { avatarVersion += 1 }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("You")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 36) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Identity

    private var identity: some View {
        VStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAvatarPicker = true
            } label: {
                MemojiAvatar(traveller: .you, size: 88)
                    .id(avatarVersion)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.ctaLabel)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.cta, in: .circle)
                            .overlay { Circle().strokeBorder(AppTheme.card, lineWidth: 2.5) }
                    }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Change your picture")

            VStack(spacing: 3) {
                Text(displayName)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(handle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .cardSurface(corner: 26)
    }

    // MARK: - Stats

    /// Read off the ledger rather than typed in. These were three invented
    /// figures — a trip count and two amounts that belonged to no trip anybody
    /// was on — sitting under the user's own name, which is the last place in
    /// the app that should be showing made-up money.
    private var stats: some View {
        HStack(spacing: 0) {
            stat(value: "\(store.trips.count)", label: store.trips.count == 1 ? "Trip" : "Trips")
            Divider().frame(height: 34).overlay(AppTheme.cardStroke.opacity(0.10))
            stat(value: Money.format(store.owedToYou, code: store.primaryCurrency), label: "Owed to you")
            Divider().frame(height: 34).overlay(AppTheme.cardStroke.opacity(0.10))
            stat(value: Money.format(store.youOwe, code: store.primaryCurrency), label: "You owe")
        }
        .padding(.vertical, 16)
        .cardSurface(corner: 22)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Settings

    private var settings: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, row in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 12) {
                        IconTile(symbol: row.symbol, tint: row.tint, size: 32, corner: 10)

                        Text(row.title)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.ink)

                        Spacer(minLength: 6)

                        if let value = row.value {
                            Text(value)
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())

                if index < Self.rows.count - 1 {
                    Hairline(inset: 16)
                }
            }
        }
        .cardSurface(corner: 22)
    }

    private struct SettingsRow {
        let title: String
        let symbol: String
        let tint: Color
        var value: String?
    }

    private static let rows: [SettingsRow] = [
        .init(title: "Payment methods", symbol: "creditcard.fill", tint: AppTheme.accent, value: "UPI"),
        .init(title: "Default currency", symbol: "indianrupeesign", tint: Palette.greenDeep, value: "INR"),
        .init(title: "Notifications", symbol: "bell.fill", tint: Palette.amberDeep, value: nil),
        .init(title: "Export trip ledger", symbol: "square.and.arrow.up", tint: Palette.violetDeep, value: nil)
    ]

    // MARK: - Sign out

    private var signOut: some View {
        Button {
            dismiss()
            onSignOut()
        } label: {
            Text("Sign out")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .cardSurface(corner: 20, shadow: 10)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProfileSheet(userName: "Swastik Patil")
    }
}
