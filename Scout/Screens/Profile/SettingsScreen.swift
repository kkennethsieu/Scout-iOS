import SwiftUI

/// Pushed from the Profile gear. A curated settings list (Legal links + account
/// actions) over the Profile's existing nav stack. Log out and Delete account
/// share `ProfileViewModel`'s account-deletion state with the Profile screen.
struct SettingsScreen: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthService.self) private var auth
    @Environment(ToastCenter.self) private var toasts: ToastCenter?
    @Environment(\.openURL) private var openURL

    /// Presents the "log out" confirmation dialog.
    @State private var showLogOutConfirm = false
    /// Presents the "delete account" confirmation dialog.
    @State private var showDeleteAccountConfirm = false
    /// Hosted legal links (`GET /legal`); `nil` until loaded — the Legal rows stay
    /// disabled until then.
    @State private var legal: LegalResponse?

    private let legalService: LegalService

    init(viewModel: ProfileViewModel, legalService: LegalService = AppServices.legal) {
        _viewModel = State(initialValue: viewModel)
        self.legalService = legalService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                legalSection
                accountActions
                versionFooter
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
        }
        .background(Color.sBackground)
        .safeAreaInset(edge: .top, spacing: 0) {
            SNavHeader(title: "Settings")
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { legal = try? await legalService.fetchLegalLinks() }
        .confirmationDialog(
            "Log out?",
            isPresented: $showLogOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                do {
                    try auth.signOut()
                    toasts?.show("Signed out")
                } catch { }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your account.")
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount() {
                        try? auth.signOut()
                        toasts?.show("Account deleted")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account, reviews, and photos. This can't be undone.")
        }
        .alert(
            "Couldn't delete account",
            isPresented: Binding(
                get: { viewModel.accountDeleteError != nil },
                set: { if !$0 { viewModel.dismissAccountDeleteError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.accountDeleteError ?? "")
        }
        .overlay {
            if viewModel.isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Deleting account…")
                        .tint(Color.sAccent)
                        .padding(Spacing.xl)
                        .background(Color.sSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
                }
            }
        }
    }

    // MARK: - Sections

    private var legalSection: some View {
        SSection(title: "Legal", titleFont: .sHeadingS) {
            SListGroup {
                SListRow(title: "Privacy Policy") { open(legal?.privacyPolicyUrl) }
                SListRow(title: "Terms of Service") { open(legal?.termsOfServiceUrl) }
            }
            .disabled(legal == nil)
        }
    }

    /// Opens a legal link in the system browser (no-op if it's missing/malformed).
    private func open(_ link: String?) {
        guard let link, let url = URL(string: link) else { return }
        openURL(url)
    }

    private var accountActions: some View {
        SListGroup {
            SListRow(title: "Log out") {
                showLogOutConfirm = true
            }
            SListRow(title: "Delete account", isDestructive: true) {
                showDeleteAccountConfirm = true
            }
        }
    }

    private var versionFooter: some View {
        Text("Scout \(AppVersion.current) (\(AppVersion.build))")
            .font(.sBodyS)
            .foregroundStyle(Color.sTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsScreen(
            viewModel: ProfileViewModel(userService: MockUserService()),
            legalService: MockLegalService()
        )
    }
    .environment(AuthService.shared)
}
