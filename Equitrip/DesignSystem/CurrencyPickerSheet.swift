//
//  CurrencyPickerSheet.swift
//  Equitrip
//

import SwiftUI

/// Picking the currency a trip is settled in.
///
/// A row plus a sheet rather than a scrolling strip of chips: the strip only
/// ever showed the handful that fit, and the one you wanted was always the one
/// off the right-hand edge.
struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: String
    @State private var query = ""

    private var matches: [CurrencyOption] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return CurrencyOption.all }
        return CurrencyOption.all.filter {
            $0.code.localizedCaseInsensitiveContains(trimmed)
                || $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            list
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var header: some View {
        HStack {
            Text("Currency")
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

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            TextField("Search currencies", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .panelSurface(corner: 16)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element.code) { index, option in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selection = option.code
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(Money.symbol(for: option.code))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.cardStroke.opacity(0.06), in: .circle)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(option.code)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                Text(option.name)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(AppTheme.inkSecondary)
                            }

                            Spacer(minLength: 6)

                            if option.code == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if index < matches.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct CurrencyOption {
    let code: String
    let name: String

    static let all: [CurrencyOption] = [
        .init(code: "INR", name: "Indian rupee"),
        .init(code: "USD", name: "US dollar"),
        .init(code: "EUR", name: "Euro"),
        .init(code: "GBP", name: "British pound"),
        .init(code: "AED", name: "UAE dirham"),
        .init(code: "THB", name: "Thai baht"),
        .init(code: "SGD", name: "Singapore dollar"),
        .init(code: "JPY", name: "Japanese yen"),
        .init(code: "AUD", name: "Australian dollar"),
        .init(code: "CAD", name: "Canadian dollar"),
        .init(code: "CHF", name: "Swiss franc"),
        .init(code: "LKR", name: "Sri Lankan rupee"),
        .init(code: "NPR", name: "Nepalese rupee"),
        .init(code: "IDR", name: "Indonesian rupiah"),
        .init(code: "MYR", name: "Malaysian ringgit"),
        .init(code: "VND", name: "Vietnamese dong")
    ]
}

// MARK: - Row

/// Collapsed form for the forms that used to carry a chip strip.
struct CurrencyRow: View {
    let code: String
    let action: () -> Void

    private var name: String {
        CurrencyOption.all.first { $0.code == code }?.name ?? code
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(Money.symbol(for: code))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.cardStroke.opacity(0.06), in: .circle)

                VStack(alignment: .leading, spacing: 1) {
                    Text(code)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(name)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .panelSurface(corner: 16)
    }
}
