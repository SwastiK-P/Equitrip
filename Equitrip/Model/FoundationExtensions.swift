//
//  FoundationExtensions.swift
//  Equitrip
//

import SwiftUI

// MARK: - Date helpers

extension DateFormatter {
    /// Formatters are expensive to build and these run inside list rows.
    static func cached(_ format: String) -> DateFormatter {
        if let existing = cache[format] { return existing }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        cache[format] = formatter
        return formatter
    }

    private nonisolated(unsafe) static var cache: [String: DateFormatter] = [:]
}

extension Int {
    /// "1 booking", "3 bookings". Counts and their nouns kept disagreeing in
    /// the copy — "1 travellers" — because every call site spelled the plural
    /// out by hand and none of them handled one.
    func pluralised(_ singular: String, _ plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : plural ?? singular + "s")"
    }
}

extension Date {
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    static func at(_ hour: Int, _ minute: Int, on day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    static func daysFromToday(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }
}
