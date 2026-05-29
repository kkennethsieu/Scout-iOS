import SwiftUI

struct CreateAccountScreen: View {
    @Environment(\.dismiss) private var dismiss

    let prefilledEmail: String

    @State private var email: String
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(prefilledEmail: String = "") {
        self.prefilledEmail = prefilledEmail
        self._email = State(initialValue: prefilledEmail)
    }

    private var isEmailValid: Bool {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.contains("@") && clean.contains(".")
    }

    private var isPasswordValid: Bool {
        password.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var isFormValid: Bool {
        isEmailValid && isPasswordValid && passwordsMatch
    }

    var body: some View {
        ZStack {
            Color.sBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SBackButton()

                    titleSection
                        .padding(.top, Spacing.lg)

                    formSection
                        .padding(.top, Spacing.xxl)

                    passwordHint
                        .padding(.top, Spacing.md)

                    SPrimaryButton(
                        title: "Create account",
                        trailingIcon: "arrow.right",
                        isLoading: isLoading
                    ) {
                        handleCreate()
                    }
                    .disabled(!isFormValid)
                    .padding(.top, Spacing.xl)
                }
                .padding(Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Couldn't create account", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Create account")
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)

            Text("Enter your details to start documenting your journey.")
                .font(.sBodyL)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            STextField(
                label: "Email Address",
                text: $email,
                placeholder: "email@example.com",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            STextField(
                label: "Password",
                text: $password,
                isSecure: true,
                textContentType: .newPassword
            )

            STextField(
                label: "Confirm Password",
                text: $confirmPassword,
                isSecure: true,
                textContentType: .newPassword
            )
        }
    }

    @ViewBuilder
    private var passwordHint: some View {
        let showMismatch = !confirmPassword.isEmpty && !passwordsMatch
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: showMismatch ? "exclamationmark.circle" : "info.circle")
                .font(.system(size: 18))
                .foregroundStyle(showMismatch ? Color.sError : Color.sTextSecondary)

            Text(showMismatch
                 ? "Passwords don't match."
                 : "Use at least 8 characters.")
                .font(.sBody)
                .foregroundStyle(showMismatch ? Color.sError : Color.sTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sBorderSubtle)
        )
    }

    // MARK: - Actions

    private func handleCreate() {
        Task {
            isLoading = true
            defer { isLoading = false }

            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try await AuthService.shared.createWithEmail(
                    email: cleanEmail,
                    password: cleanPassword
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview("Create Account") {
    CreateAccountScreen()
}

#Preview("Create Account — Dark") {
    CreateAccountScreen()
        .preferredColorScheme(.dark)
}
