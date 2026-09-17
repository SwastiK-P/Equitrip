//
//  EquiHistorySheet.swift
//  Equitrip
//

import SwiftUI

/// Every conversation Equi has had with this account, newest first.
///
/// Reached from the clock in the tab's header. Deliberately a list of
/// *questions* rather than of dates: a thread is remembered by what was asked
/// — "how much have we spent on food?" — and a column of timestamps is a thing
/// you have to open one by one to search. The date is the caption.
///
/// Grouped under Today / Yesterday / the month, the way Messages and Mail
/// shelve the same problem: it turns one long scroll into a handful of short
/// ones without asking anybody to type into a search field. The rows
/// themselves are `EquiConversationList`, shared with the wide-iPad sidebar.
struct EquiHistorySheet: View {
    @Environment(\.dismiss) private var dismiss

    let history: EquiHistoryStore
    var onOpen: (EquiConversationSummary) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(
                title: "Conversations",
                caption: history.conversations.isEmpty
                    ? "What you've asked Equi"
                    : history.conversations.count.pluralised("conversation")
            )

            if let failure = history.failure {
                Text(failure)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }

            ScrollView {
                EquiConversationList(history: history) { conversation in
                    onOpen(conversation)
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background { CanvasBackground() }
    }
}
