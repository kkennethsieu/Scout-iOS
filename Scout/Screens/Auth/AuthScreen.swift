import SwiftUI
import AuthenticationServices

struct AuthScreen: View {
    /// `true` when presented as a sign-in sheet (from `AuthGate`) rather than as
    /// the app root: adds a close button and respects the safe area.
    var isModal = false

    @Environment(\.dismiss) private var dismiss

    @State private var showEmailFlow = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Top: logo + title
            topSection
            
            // Middle: photo collage
            photoCollage
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
            
            Spacer(minLength: Spacing.xl)
            
            // Bottom: auth buttons + legal
            authButtons
                .padding(.horizontal, Spacing.lg)
            
            legalText
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.md)
        }
        .padding(.top, Spacing.xxxl)
        .padding()
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .background(Color.sBackground)
        // Full-bleed as the app root; respect the safe area inside a sheet.
        .ignoresSafeArea(edges: isModal ? [] : .all)
        .overlay(alignment: .topTrailing) {
            if isModal { closeButton }
        }
        .sheet(isPresented: $showEmailFlow) {
            AuthEmailScreen()
        }
        .alert("Sign in failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Top
    
    private var topSection: some View {
        VStack(spacing: Spacing.lg) {
            logo
            
            VStack(spacing: Spacing.xs) {
                Text("Find your next shot")
                    .font(.sDisplayM)
                    .foregroundStyle(Color.sTextPrimary)
                
                Text("Share where you stood")
                    .font(.sBodyL)
                    .foregroundStyle(Color.sTextSecondary)
            }
        }
        .padding(.top, Spacing.xxxl)
    }
    
    private var logo: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.sAccent)
            .frame(width: 72, height: 72)
            .overlay {
                Image("logo")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.white)
            }
    }
    
    // MARK: - Photo Collage
    
    private var photoCollage: some View {
        HStack(spacing: Spacing.md) {
            // Left: large square
            photoTile("auth-mountain")
                .aspectRatio(1, contentMode: .fit)
            
            // Right: two stacked
            VStack(spacing: Spacing.md) {
                photoTile("auth-dew")
                photoTile("auth-forest")
            }
        }
        .frame(maxHeight: 280)
    }
    
    @ViewBuilder
    private func photoTile(_ assetName: String) -> some View {
        Group {
            if !assetName.isEmpty {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.sAccentSoft
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.sTextTertiary)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
    
    // MARK: - Auth Buttons
    
    private var authButtons: some View {
        VStack(spacing: Spacing.md) {
            appleSignInButton
            googleSignInButton
            orDivider
            SSecondaryButton(title: "Continue with email") {
                showEmailFlow = true
            }
        }
    }
    
    private var appleSignInButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
            request.nonce = AuthService.shared.prepareAppleSignInNonce()
        } onCompletion: { result in
            handleAppleSignIn(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
    
    private var googleSignInButton: some View {
        Button {
            handleGoogleSignIn()
        } label: {
            HStack(spacing: Spacing.sm) {
                googleLogo
                Text("Continue with Google")
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.sSurface)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.sBorderDefault, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
    }
    
    @ViewBuilder
    private var googleLogo: some View {
        Image("google-logo")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
    }
    
    private var orDivider: some View {
        HStack(spacing: Spacing.md) {
            Rectangle()
                .fill(Color.sBorderSubtle)
                .frame(height: 0.5)
            Text("or")
                .font(.sBodyS)
                .foregroundStyle(Color.sTextTertiary)
            Rectangle()
                .fill(Color.sBorderSubtle)
                .frame(height: 0.5)
        }
    }
    
    // MARK: - Legal
    
    private var legalText: some View {
        Text(legalAttributedString)
            .font(.sBodyS)
            .foregroundStyle(Color.sTextTertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .tint(Color.sTextSecondary)
    }

    private var legalAttributedString: AttributedString {
        // Explicit break keeps this to two balanced lines rather than truncating.
        var result = AttributedString("By continuing, you agree to Scout's\n")
        
        var terms = AttributedString("Terms of Service")
        terms.underlineStyle = .single
        terms.foregroundColor = Color.sTextSecondary
        terms.link = URL(string: "https://scout.app/terms")
        result += terms
        
        result += AttributedString(" and ")
        
        var privacy = AttributedString("Privacy Policy")
        privacy.underlineStyle = .single
        privacy.foregroundColor = Color.sTextSecondary
        privacy.link = URL(string: "https://scout.app/privacy")
        result += privacy
        
        result += AttributedString(".")
        
        return result
    }
    
    // MARK: - Close (modal only)

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.sTextSecondary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.sSurface))
        }
        .padding(.top, Spacing.lg)
        .padding(.trailing, Spacing.lg)
        .accessibilityLabel("Close")
    }

    // MARK: - Actions

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        Task {
            do {
                try await AuthService.shared.signInWithApple(authorization: result)
            } catch {
                if (error as? ASAuthorizationError)?.code != .canceled {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
    
    private func handleGoogleSignIn() {
        isLoading = true
        Task {
            do {
                try await AuthService.shared.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview("Auth Screen") {
    AuthScreen()
}

#Preview("Auth Screen — Dark") {
    AuthScreen()
        .preferredColorScheme(.dark)
}

#Preview("Auth Screen — Modal") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            AuthScreen(isModal: true)
        }
}
