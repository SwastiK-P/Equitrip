//
//  ItineraryIssue.swift
//  Equitrip
//

import SwiftUI

/// Something on the plan that doesn't add up.
///
/// Two very different engines produce these — arithmetic in
/// `ItineraryConsistency` and judgement in `ItineraryInspector` — and they
/// meet here so the screen only has one shape to draw. `origin` is kept
/// because the two are not equally trustworthy: a clash between two clock
/// times is a fact, and a hunch that a temple will be shut at eleven at night
/// is a hunch, and the copy is allowed to know the difference.
///
/// Nothing here is ever written anywhere. An issue lives as long as the review
/// screen does and is recomputed from the bookings every time they change,
/// which is the only way a warning about a booking can't outlive the fix.
struct ItineraryIssue: Identifiable, Hashable {

    /// How sure we are that this is wrong.
    ///
    /// Only two levels on purpose. Three invites a middle that nobody can
    /// define, and the reader's real question is binary — do I have to deal
    /// with this before I press Create, or is it just worth a look.
    enum Severity: Int, Comparable {
        case worthChecking
        case likelyWrong

        static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

        var tint: Color {
            switch self {
            case .likelyWrong: AppTheme.danger
            case .worthChecking: Palette.amber
            }
        }
    }

    enum Origin {
        /// Found by arithmetic. Every figure in the text was formatted in Swift.
        case rules
        /// Found by the on-device model. Validated against real bookings first.
        case intelligence
    }

    let id: UUID
    var severity: Severity
    /// The glyph for the row's badge.
    var symbol: String
    /// What's wrong, in a handful of words.
    var headline: String
    /// One sentence explaining it.
    var problem: String
    /// One sentence saying what to change.
    var fix: String
    /// The bookings this is about. Always real IDs of bookings that exist —
    /// the model's are dropped when they can't be matched to one.
    var itemIDs: [UUID]
    var origin: Origin
    /// When on the trip this happens. Carried for ordering only: issues read
    /// as a list of things to go and fix, and a list of things to go and fix
    /// is in the order you'd walk through them.
    var anchor: Date

    init(
        id: UUID = UUID(),
        severity: Severity,
        symbol: String,
        headline: String,
        problem: String,
        fix: String,
        itemIDs: [UUID],
        origin: Origin,
        anchor: Date
    ) {
        self.id = id
        self.severity = severity
        self.symbol = symbol
        self.headline = headline
        self.problem = problem
        self.fix = fix
        self.itemIDs = itemIDs
        self.origin = origin
        self.anchor = anchor
    }
}

// MARK: - Where the check has got to

/// The review card's three states, in the order they happen.
enum ItineraryCheckState: Equatable {
    /// Rules have run; the model is still reading.
    case checking
    /// Finished. `usedFallback` when Apple Intelligence never got involved —
    /// the screen says so rather than claiming an accuracy nobody got, the
    /// same promise `TripReviewStage.importNote` already makes about the
    /// reader that produced the bookings.
    case done(usedFallback: Bool)
}
