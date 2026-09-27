//
//  TrainTrackingSection.swift
//  Equitrip
//

import SwiftUI

/// The booking editor's PNR field for a train: type the ten digits, look it
/// up, get the ticket. Its own view rather than more of `ItineraryItemEditor`,
/// which was already past the size where a screen gets split.
struct TrainTrackingSection: View {
    @Binding var item: ItineraryItem

    @State private var pnrText: String
    @State private var isLookingUp = false
    @State private var error: String?

    init(item: Binding<ItineraryItem>) {
        _item = item
        _pnrText = State(initialValue: item.wrappedValue.train?.pnr ?? "")
    }

    private var digits: String { pnrText.filter(\.isNumber) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PNR TRACKING")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                field
                Hairline(inset: 0)
                lookupButton
            }
            .panelSurface(corner: 20)

            if let error {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 1)
                    Text(error)
                        .font(.system(size: 12.5))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(AppTheme.danger)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.danger.opacity(0.08), in: .rect(cornerRadius: 14, style: .continuous))
            }

            if let train = item.train, train.isResolved {
                TrainTicketCard(train: train, fallbackDeparture: item.time)
                if let checked = train.lastChecked {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 10.5, weight: .semibold))
                        Text("Checked \(DateFormatter.cached("d MMM, h:mm a").string(from: checked))")
                            .font(.system(size: 11.5))
                    }
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.horizontal, 2)
                }
            } else {
                Text("Look it up to pull in the train, stations, berths and live running status. The PNR is saved either way.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: item.train)
        .onChange(of: pnrText) { _, newValue in
            error = nil
            let clean = String(newValue.filter(\.isNumber).prefix(10))
            if clean != newValue { pnrText = clean }
            // Saved even unresolved, so it can be looked up later.
            if clean.count == 10, item.train?.pnr != clean {
                item.train = TrainDetails(pnr: clean, passengers: [])
            }
        }
    }

    private var field: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: "tram.fill", tint: ItineraryKind.train.tint, size: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text("PNR NUMBER")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)
                TextField("1234567890", text: $pnrText)
                    .font(.system(size: 21, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.ink)
                    .keyboardType(.numberPad)
                    .onSubmit { Task { await lookUp() } }
            }

            Spacer(minLength: 6)

            Text("\(digits.count)/10")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(digits.count == 10 ? AppTheme.positive : AppTheme.inkTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var lookupButton: some View {
        let enabled = digits.count == 10 && !isLookingUp
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { await lookUp() }
        } label: {
            HStack(spacing: 9) {
                Group {
                    if isLookingUp {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Check PNR status")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(item.train?.isResolved == true ? "Refresh berths and live status" : "Train, berths and live status")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }

    private func lookUp() async {
        guard digits.count == 10, !isLookingUp else { return }
        isLookingUp = true
        error = nil
        defer { isLookingUp = false }

        do {
            let details = try await TrainLookupService.lookup(pnr: digits, previous: item.train)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                item.train = details
                // The ticket's journey date beats whatever day the booking was
                // filed under.
                if let date = details.journeyDate { item.date = date }
                if item.title.trimmingCharacters(in: .whitespaces).isEmpty,
                   let from = details.from?.code, let to = details.to?.code {
                    item.title = "\(details.displayName) \(from) → \(to)"
                }
                if item.vendor.isEmpty, let number = details.trainNumber { item.vendor = "Train \(number)" }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            self.error = (error as? TrainLookupService.LookupError)?.errorDescription ?? "Couldn't look that up."
        }
    }
}
