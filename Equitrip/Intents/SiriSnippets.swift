//
//  SiriSnippets.swift
//  Equitrip
//

import SwiftUI

/// The cards Siri shows under an answer or above a confirmation.
///
/// Drawn in system colours rather than `AppTheme`'s, which is the one place in
/// the app that does: a snippet sits on Siri's own glass, in whatever
/// appearance the phone is in, and the app's light-only palette read as a
/// white slab pasted onto a dark Siri card. The accent and the money tones are
/// the only brand colours that survive, because they carry meaning.
///
/// Every figure here comes off the ledger the moment the card is drawn.
struct SiriBalanceSnippet: View {
    let tripTitle: String
    let net: Double
    let currencyCode: String
    /// Who you pay, or who pays you, already minimised.
    let transfers: [(name: String, amount: Double, youPay: Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tripTitle.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(net == 0 ? "All square" : Money.format(abs(net), code: currencyCode))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(tone)
                if net != 0 {
                    Text(net > 0 ? "coming back to you" : "you owe")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(transfers.prefix(4).enumerated()), id: \.offset) { _, transfer in
                HStack {
                    Image(systemName: transfer.youPay ? "arrow.up.right" : "arrow.down.left")
                        .foregroundStyle(transfer.youPay ? AppTheme.moneyOut : AppTheme.moneyIn)
                    Text(transfer.youPay ? "You pay \(transfer.name)" : "\(transfer.name) pays you")
                    Spacer()
                    Text(Money.format(transfer.amount, code: currencyCode))
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tone: Color {
        net > 0 ? AppTheme.moneyIn : net < 0 ? AppTheme.moneyOut : .primary
    }
}

/// What's coming up, as a short timeline.
struct SiriUpNextSnippet: View {
    struct Row: Identifiable {
        let id: UUID
        let symbol: String
        let title: String
        let when: String
        let detail: String?
    }

    let tripTitle: String
    let rows: [Row]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tripTitle.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(rows) { row in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: row.symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title).font(.body.weight(.semibold))
                        Text(row.when).font(.subheadline).foregroundStyle(.secondary)
                        if let detail = row.detail {
                            Text(detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The expense Siri is about to write, laid out so every figure can be checked
/// before anything is saved — the card the voice path exists behind.
struct SiriExpenseSnippet: View {
    let title: String
    let amount: Double
    let currencyCode: String
    let tripTitle: String
    let payerName: String
    let splitLabel: String
    let eachLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tripTitle.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.title3.weight(.semibold))
                Spacer()
                Text(Money.format(amount, code: currencyCode))
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }

            Divider()

            fact("Paid by", payerName, symbol: "creditcard")
            fact("Split", splitLabel, symbol: "person.2")
            if let eachLabel { fact("Each", eachLabel, symbol: "equal") }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fact(_ label: String, _ value: String, symbol: String) -> some View {
        HStack {
            Label(label, systemImage: symbol).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}
