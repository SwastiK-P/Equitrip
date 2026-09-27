//
//  EquiContext.swift
//  Equitrip
//

import Foundation

/// The briefing Equi's reply is written from: who it's talking to, the facts
/// that answer this one question, and how to say it.
///
/// It used to be every trip the user had, bookings and all, capped at four —
/// which was both too much and too little. Too much for a small on-device
/// model to keep straight (answers about one trip borrowed figures from
/// another), and too little for questions about older trips, which the cap
/// dropped first. Now `EquiFacts` has already worked the answer out, and this
/// briefs the model on those facts alone, rebuilt for every question so it
/// never lags behind something logged mid-conversation.
enum EquiContext {

    @MainActor
    static func instructions(for facts: EquiFacts) -> String {
        let you = Traveller.you
        var lines: [String] = []

        lines.append("You are Equi, the trip assistant in Equitrip, a group travel-planning and expense-splitting app. You're talking with \(you.name). Today is \(DateFormatter.cached("EEEE d MMMM yyyy").string(from: Date())).")
        lines.append("")
        lines.append("Answer the user's latest question directly, in one to three short sentences, like a sharp, friendly travel buddy. Lead with the answer itself; add a second detail only if it genuinely helps. Speak to the user as \"you\". Vary your wording — don't open with their name or a greeting, and don't repeat the question back.")
        if facts.card != nil {
            lines.append("A card under your reply shows the full breakdown, so don't list everything — pick what answers the question.")
        }
        lines.append("")
        lines.append("Facts — the only source for anything about their trips, bookings, people, dates and money:")
        lines.append(contentsOf: facts.lines.map { "- \($0)" })
        lines.append("The short answer, to put in your own words: \(facts.headline)")
        lines.append("")
        lines.append("Use amounts, dates and names exactly as written in the facts; never work out a new figure or total. If the facts don't cover what was asked, say what you do know and what isn't recorded in the app.")
        if facts.allowsGeneralKnowledge {
            lines.append("You may add general travel knowledge — typical weather, what to pack, well-known sights, local food — as suggestions, never as something already booked or paid.")
        } else {
            lines.append("Stick to the facts; don't give general travel advice unless asked.")
        }

        return lines.joined(separator: "\n")
    }
}
