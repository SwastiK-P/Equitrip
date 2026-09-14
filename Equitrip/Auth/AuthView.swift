//
//  AuthView.swift
//  Equitrip
//

import SwiftUI

enum AuthMode {
    case signIn
    case createAccount

    var title: String {
        switch self {
        case .signIn: "Welcome back."
        case .createAccount: "Create your account."
        }
    }

    var subtitle: String {
        switch self {
        case .signIn: "Pick up your trips exactly where you left them."
        case .createAccount: "Start a trip, invite the group, split everything fairly."
        }
    }

    var actionTitle: String {
        switch self {
        case .signIn: "Sign in"
        case .createAccount: "Create account"
        }
    }

    var footerPrompt: String {
        switch self {
        case .signIn: "New to Equitrip?"
        case .createAccount: "Already have an account?"
        }
    }

    var footerAction: String {
        switch self {
        case .signIn: "Create account"
        case .createAccount: "Sign in"
        }
    }

    var opposite: AuthMode {
        self == .signIn ? .createAccount : .signIn
    }
}

struct AuthView: View {
    @Environment(\.pane) private var pane

    let mode: AuthMode
    var onBack: () -> Void = {}
    var onSwitchMode: (AuthMode) -> Void = { _ in }
    var onAuthenticated: () -> Void = {}

    private enum Field: Hashable { case name, email, password }

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var noticeMessage: String?
    @State private var shakeCount = 0
    @State private var isSubmitting = false
    @State private var appeared = false
    @FocusState private var focus: Field?

    var body: some View {
        ZStack {
            CanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    fields
                        .padding(.top, 30)

                    if let errorMessage {
                        banner(errorMessage, symbol: "exclamationmark.triangle.fill", tint: AppTheme.danger)
                            .padding(.top, 14)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let noticeMessage {
                        banner(noticeMessage, symbol: "envelope.badge.fill", tint: AppTheme.accent)
                            .padding(.top, 14)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if mode == .signIn {
                        Button {} label: {
                            Text("Forgot password?")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 14)
                        .staggered(appeared, index: fieldCount)
                    }

                    PrimaryButton(
                        title: mode.actionTitle,
                        isLoading: isSubmitting,
                        action: submit
                    )
                    .padding(.top, 26)
                    .shake(shakeCount)
                    .staggered(appeared, index: fieldCount + 1)

                    separator
                        .padding(.top, 22)
                        .staggered(appeared, index: fieldCount + 2)

                    appleButton
                        .padding(.top, 16)
                        .staggered(appeared, index: fieldCount + 3)

                    TextButton(
                        title: mode.footerPrompt,
                        emphasis: mode.footerAction
                    ) {
                        onSwitchMode(mode.opposite)
                    }
                    .padding(.top, 12)
                    .staggered(appeared, index: fieldCount + 4)

                    if mode == .createAccount {
                        Text("By creating an account you agree to our Terms and Privacy Policy.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                            .padding(.horizontal, 16)
                            .staggered(appeared, index: fieldCount + 5)
                    }
                }
                .padding(.horizontal, 24)
                // A sign-in form is four controls in a stack; stretched across
                // a landscape iPad each field becomes a 1200pt trough with a
                // caret at one end. Capped tighter than the app's usual prose
                // measure — a form column wants to be about as wide as its
                // widest field needs to be and no wider — and centred in the
                // window rather than pinned to the top left of it.
                .frame(maxWidth: pane.isRegular ? 460 : .infinity)
                .frame(maxWidth: .infinity)
                // Top-aligned, not centred: the form grows by a field when
                // you switch to Create account and shrinks again coming back,
                // and a centred column moves every control on the screen each
                // time it does. Kept off the very top instead, which reads as
                // placed rather than as stuck to the edge.
                .padding(.top, pane.isRegular ? 40 : 0)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { appeared = true }
        }
    }

    /// Create-account carries one extra field, which shifts every later stagger.
    private var fieldCount: Int { mode == .createAccount ? 3 : 2 }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.card, in: .circle)
                    .overlay {
                        Circle().strokeBorder(AppTheme.cardStroke.opacity(0.06))
                    }
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 8)

            Text(mode.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 26)
                .staggered(appeared, index: 0)

            Text(mode.subtitle)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
                .staggered(appeared, index: 1)
        }
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(spacing: 16) {
            if mode == .createAccount {
                EquitripField(
                    label: "Full name",
                    placeholder: "Swastik Patil",
                    text: $name,
                    contentType: .name,
                    focus: $focus,
                    field: Field.name,
                    onSubmit: { focus = .email }
                )
                .staggered(appeared, index: 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            EquitripField(
                label: "Email",
                placeholder: "you@example.com",
                text: $email,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                focus: $focus,
                field: Field.email,
                onSubmit: { focus = .password }
            )
            .staggered(appeared, index: mode == .createAccount ? 3 : 2)

            EquitripField(
                label: "Password",
                placeholder: mode == .createAccount ? "At least 8 characters" : "Your password",
                text: $password,
                isSecure: true,
                contentType: mode == .createAccount ? .newPassword : .password,
                submitLabel: .go,
                focus: $focus,
                field: Field.password,
                onSubmit: submit
            )
            .staggered(appeared, index: mode == .createAccount ? 4 : 3)
        }
        .shake(shakeCount)
    }

    private func banner(_ message: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(tint.opacity(0.10), in: .rect(cornerRadius: 13))
    }

    // MARK: - Alternate sign-in

    private var separator: some View {
        HStack(spacing: 12) {
            line
            Text("or")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.10))
            .frame(height: 1)
    }

    private var appleButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 17, weight: .medium))
                Text("Continue with Apple")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.card, in: .rect(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.09))
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Submit

    private func submit() {
        focus = nil

        if let failure = validationFailure() {
            reject(failure)
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            errorMessage = nil
            noticeMessage = nil
        }
        isSubmitting = true

        Task {
            do {
                switch mode {
                case .signIn:
                    try await AuthService.shared.signIn(email: email, password: password)
                    isSubmitting = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onAuthenticated()

                case .createAccount:
                    let signedIn = try await AuthService.shared.signUp(
                        name: name,
                        email: email,
                        password: password
                    )
                    isSubmitting = false

                    if signedIn {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        onAuthenticated()
                    } else {
                        // Project requires email confirmation — account made,
                        // but there's no session to move forward with yet.
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            noticeMessage = "Almost there — confirm your email, then sign in."
                        }
                    }
                }
            } catch {
                isSubmitting = false
                reject(AuthService.message(for: error))
            }
        }
    }

    private func reject(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            errorMessage = message
            noticeMessage = nil
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            shakeCount += 1
        }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    private func validationFailure() -> String? {
        if mode == .createAccount, name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter your name."
        }
        guard email.contains("@"), email.contains(".") else {
            return "That email doesn't look right."
        }
        let minimum = mode == .createAccount ? 8 : 1
        guard password.count >= minimum else {
            return mode == .createAccount
                ? "Password needs at least 8 characters."
                : "Please enter your password."
        }
        return nil
    }
}

// MARK: - Stagger

private extension View {
    /// Entrance offset + fade, delayed by position so the form assembles
    /// top-down rather than appearing all at once.
    func staggered(_ appeared: Bool, index: Int) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.85)
                .delay(0.06 + Double(index) * 0.06),
                value: appeared
            )
    }
}

#Preview("Sign in") {
    AuthView(mode: .signIn)
}

#Preview("Create account") {
    AuthView(mode: .createAccount)
        .preferredColorScheme(.dark)
}
