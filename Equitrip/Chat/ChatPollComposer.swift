//
//  ChatPollComposer.swift
//  Equitrip
//

import SwiftUI

/// Asking the group something with a countable answer.
struct ChatPollComposer: View {
    @Environment(\.dismiss) private var dismiss

    var onSend: (ChatAttachment) -> Void

    @State private var question = ""
    @State private var options: [ChatAttachment.Option] = [.init(text: ""), .init(text: "")]
    @State private var allowsMultiple = false
    @FocusState private var focusedOption: String?

    private static let maxOptions = 8

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "New poll", caption: "Everyone on the trip can vote and change their vote.")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassField(label: "Question", placeholder: "Which beach tomorrow?", text: $question, autocapitalisation: .sentences)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Options")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkSecondary)

                        ForEach($options) { $option in
                            HStack(spacing: 10) {
                                Image(systemName: allowsMultiple ? "square" : "circle")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppTheme.inkTertiary)

                                TextField("Option", text: $option.text)
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppTheme.ink)
                                    .focused($focusedOption, equals: option.id)
                                    .submitLabel(.next)
                                    .onSubmit { advance(from: option.id) }

                                if options.count > 2 {
                                    Button {
                                        withAnimation(.snappy) { options.removeAll { $0.id == option.id } }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppTheme.inkTertiary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Remove option")
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .panelSurface(corner: 14)
                        }

                        if options.count < Self.maxOptions {
                            Button {
                                let option = ChatAttachment.Option(text: "")
                                withAnimation(.snappy) { options.append(option) }
                                focusedOption = option.id
                            } label: {
                                Label("Add option", systemImage: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }

                    Toggle(isOn: $allowsMultiple) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Allow several answers")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.ink)
                            Text("For \"which days are you free?\" rather than \"which one?\"")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.inkSecondary)
                        }
                    }
                    .tint(AppTheme.accent)
                    .padding(14)
                    .panelSurface(corner: 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: "Send poll", systemImage: nil, isEnabled: isValid) {
                onSend(.poll(.init(question: trimmedQuestion, options: filledOptions, allowsMultiple: allowsMultiple)))
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var trimmedQuestion: String { question.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Blank rows are dropped rather than refused — leaving a spare empty
    /// option at the bottom is how people type lists.
    private var filledOptions: [ChatAttachment.Option] {
        options
            .map { .init(id: $0.id, text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.text.isEmpty }
    }

    private var isValid: Bool { !trimmedQuestion.isEmpty && filledOptions.count >= 2 }

    private func advance(from id: String) {
        guard let index = options.firstIndex(where: { $0.id == id }) else { return }
        if index + 1 < options.count {
            focusedOption = options[index + 1].id
        } else if options.count < Self.maxOptions {
            let option = ChatAttachment.Option(text: "")
            options.append(option)
            focusedOption = option.id
        }
    }
}
