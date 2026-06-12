import SwiftUI

/// Pushed from the Profile gear. A curated settings list (Account / Legal / account
/// actions) over the Profile's existing nav stack. Most rows are stubbed for now;
/// the real wiring is Log out and Delete account, which share `ProfileViewModel`'s
/// account-deletion state with the Profile screen.
struct SettingsScreen: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthService.self) private var auth

    /// Presents the "delete account" confirmation dialog.
    @State private var showDeleteAccountConfirm = false

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                accountSection
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
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount() {
                        try? auth.signOut()
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

    private var accountSection: some View {
        SSection(title: "Account", titleFont: .sHeadingS) {
            SListGroup {
                SListRow(title: "Push notifications") {}
                SListRow(title: "Email notifications") {}
            }
        }
    }

    private var legalSection: some View {
        SSection(title: "Legal", titleFont: .sHeadingS) {
            SListGroup {
                SListRow(title: "Privacy Policy") {}
                SListRow(title: "Terms of Service") {}
            }
        }
    }

    private var accountActions: some View {
        SListGroup {
            SListRow(title: "Log out") {
                try? auth.signOut()
            }
            SListRow(title: "Delete account", isDestructive: true) {
                showDeleteAccountConfirm = true
            }
        }
    }

    private var versionFooter: some View {
        Text("Scout 1.0 (1)")
            .font(.sBodyS)
            .foregroundStyle(Color.sTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsScreen(viewModel: ProfileViewModel(userService: MockUserService()))
    }
    .environment(AuthService.shared)
}
