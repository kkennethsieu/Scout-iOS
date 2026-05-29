import SwiftUI

struct ForgotPasswordScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    let prefilledEmail: String
    
    @State private var email: String
    @State private var isLoading = false
    @State private var hasSent = false
    @State private var errorMessage: String?
    
    init(prefilledEmail: String = "") {
        self.prefilledEmail = prefilledEmail
        self._email = State(initialValue: prefilledEmail)
    }
    
    private var isEmailValid: Bool {
        email.contains("@") && email.count >= 5
    }
    
    var body: some View {
        ZStack {
            Color.sBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                SBackButton()
                if hasSent {
                    successView
                } else {
                    inputView
                }
            }
            .padding(Spacing.xl)
        }
        .animation(.easeInOut(duration: 0.3), value: hasSent)
        .alert("Couldn't send reset link", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Input state
    
    private var inputView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                    .padding(.top, Spacing.xl)
                
                STextField(
                    label: "Email Address",
                    text: $email,
                    placeholder: "email@example.com",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )
                .padding(.top, Spacing.xxl)
                
                SPrimaryButton(
                    title: "Send reset link",
                    trailingIcon: "arrow.right",
                    isLoading: isLoading
                ) {
                    handleSend()
                }
                .disabled(!isEmailValid)
                .padding(.top, Spacing.xl)
            }
            .padding(.bottom, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Forgot password?")
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)
            
            Text("Enter your email and we'll send you a link to reset it.")
                .font(.sBodyL)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Success state
    
    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.sSuccess)
                    .symbolEffect(.bounce, value: hasSent)
                
                VStack(spacing: Spacing.sm) {
                    Text("Check your email")
                        .font(.sDisplayM)
                        .foregroundStyle(Color.sTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("We sent a reset link to **\(email)**. Open it to set a new password.")
                        .font(.sBodyL)
                        .foregroundStyle(Color.sTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            SPrimaryButton(title: "Done") {
                dismiss()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }
    
    // MARK: - Actions
    
    private func handleSend() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await AuthService.shared.sendPasswordReset(email: email)
                withAnimation {
                    hasSent = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview("Forgot Password — Empty") {
    ForgotPasswordScreen()
}

#Preview("Forgot Password — Prefilled") {
    ForgotPasswordScreen(prefilledEmail: "user@example.com")
}
