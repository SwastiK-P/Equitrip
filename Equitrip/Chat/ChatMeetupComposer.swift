//
//  ChatMeetupComposer.swift
//  Equitrip
//

import SwiftUI

/// Proposing a time for the group to be somewhere — "lobby at 7".
///
/// Defaults to the next round half hour, and offers the trip's own stays and
/// restaurants as places, which is where almost every meetup lands.
struct ChatMeetupComposer: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    var onSend: (ChatAttachment) -> Void

    @State private var title = ""
    @State private var date = ChatMeetupComposer.nextHalfHour()
    @State private var place = ""

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "New meetup", caption: "People answer Going, Maybe or Can't.")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassField(label: "What", placeholder: "Dinner at the shack", text: $title, autocapitalisation: .sentences)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("When")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkSecondary)

                        DatePicker("When", selection: $date, in: range, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.accent)
                            .labelsHidden()
                            .padding(8)
                            .panelSurface(corner: 16)
                    }

                    GlassField(label: "Where (optional)", placeholder: "Hotel lobby", text: $place, symbol: "mappin")

                    if !suggestions.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button { place = suggestion } label: {
                                        Text(suggestion)
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
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: "Send meetup", systemImage: nil, isEnabled: isValid) {
                let spot = place.trimmingCharacters(in: .whitespacesAndNewlines)
                onSend(.meetup(.init(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    date: date,
                    place: spot.isEmpty ? nil : spot
                )))
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// From now to the end of the trip's last day — or a week out, for a trip
    /// that's already over and still chatting.
    private var range: ClosedRange<Date> {
        let now = Date()
        let end = max(trip.endDate.endOfDay, now.addingTimeInterval(7 * 86_400))
        return now...end
    }

    /// Places the trip already knows about: where you're staying, where the
    /// dinners are booked.
    private var suggestions: [String] {
        let vendors = trip.items
            .filter { [.stay, .meal, .activity].contains($0.kind) }
            .compactMap(\.vendorName)
        return Array(NSOrderedSet(array: vendors).array.compactMap { $0 as? String }.prefix(6))
    }

    private static func nextHalfHour() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let minute = parts.minute ?? 0
        parts.minute = minute < 30 ? 30 : 0
        let rounded = calendar.date(from: parts) ?? now
        return minute < 30 ? rounded : calendar.date(byAdding: .hour, value: 1, to: rounded) ?? rounded
    }
}
