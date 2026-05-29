import SwiftUI

struct AuthEmailScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var showCreateAccount = false

    private var isFormValid: Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleanEmail.contains("@")
            && cleanEmail.contains(".")
            && cleanPassword.count >= 8
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
                    
                    infoCallout
                        .padding(.top, Spacing.lg)
                    
                    SPrimaryButton(
                        title: "Continue",
                        trailingIcon: "arrow.right",
                        isLoading: isLoading
                    ) {
                        handleContinue()
                    }
                    .disabled(!isFormValid)
                    .padding(.top, Spacing.xl)
                    
                    forgotPasswordButton
                        .padding(.top, Spacing.md)
                        .frame(maxWidth: .infinity)

                    signUpButton
                        .padding(.top, Spacing.lg)
                        .frame(maxWidth: .infinity)
                }
                .padding(Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Couldn't continue", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordScreen(prefilledEmail: email)
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountScreen(prefilledEmail: email)
        }
    }
    
    // MARK: - Sections
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sign in")
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)

            Text("Welcome back. Enter your details to continue documenting your journey.")
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
                textContentType: .password
            )
        }
    }
    
    private var infoCallout: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "info.circle")
                .font(.system(size: 18))
                .foregroundStyle(Color.sTextSecondary)
            
            Text("Use the email and password for your existing account.")
                .font(.sBody)
                .foregroundStyle(Color.sTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sBorderSubtle)
        )
    }
    
    private var forgotPasswordButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showForgotPassword = true
        } label: {
            Text("Forgot password?")
                .font(.sBodyL)
                .foregroundStyle(Color.sTextSecondary)
        }
    }

    private var signUpButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showCreateAccount = true
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("Don't have an account?")
                    .foregroundStyle(Color.sTextSecondary)
                Text("Sign up")
                    .foregroundStyle(Color.sAccent)
            }
            .font(.sBodyL)
        }
    }

    // MARK: - Actions
    
    private func handleContinue() {
        Task {
            isLoading = true
            defer { isLoading = false }

            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try await AuthService.shared.signInWithEmail(
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

#Preview("Email Auth") {
    AuthEmailScreen()
}

#Preview("Email Auth — Dark") {
    AuthEmailScreen()
        .preferredColorScheme(.dark)
}
