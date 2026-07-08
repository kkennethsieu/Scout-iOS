import SwiftUI

/// The Profile root: a custom top bar (settings + more), the user header, and
/// the user's reviews. (The Photos tab is hidden for v1 until it's
/// service-backed.)
struct ProfileScreen: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthService.self) private var auth
    @Environment(AuthGate.self) private var authGate: AuthGate?

    /// True when the Profile tab is the active one. Toggling it true refetches
    /// the profile doc + reviews, so the count stays fresh each time it's shown.
    var isActive: Bool

    /// Pushes the Edit Profile sub-screen (triggered from the "more" menu, which
    /// can't host a value-based `NavigationLink`).
    @State private var showEditProfile = false

    init(isActive: Bool = true, viewModel: ProfileViewModel = ProfileViewModel()) {
        self.isActive = isActive
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if auth.isAuthenticated {
                    signedInContent
                } else {
                    signedOutState
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { spotID in
                SpotDetailScreen(spotID: spotID)
            }
            .navigationDestination(for: SettingsRoute.self) { _ in
                SettingsScreen(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showEditProfile) {
                if let profile = viewModel.profile {
                    EditProfileScreen(profile: profile) { updated in
                        viewModel.applyUpdatedProfile(updated)
                    }
                }
            }
            .enableSwipeBack()
        }
        .task(id: isActive) {
            // Refetch whenever the Profile tab becomes the active one — but only
            // when signed in; the profile doc is user-scoped.
            if isActive, auth.isAuthenticated { await viewModel.load() }
        }
    }

    // MARK: - Content

    private var signedInContent: some View {
        ScrollView {
            Color.clear.frame(height: 0).id("top")

            VStack(spacing: 0) {
                ProfileHeader(profile: viewModel.profile)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                // Photos tab hidden for v1 (no service-backed photos yet) —
                // the profile shows the user's reviews directly.
                ProfileReviewsList(viewModel: viewModel)
                    .padding(Spacing.lg)
                    .padding(.top, Spacing.sm)
            }
        }
        .scrollsToTopOnTabRetap()
        .background(Color.sBackground)
        .refreshable { await viewModel.load() }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
    }

    private var signedOutState: some View {
        SEmptyStateView(
            icon: "person.crop.circle",
            title: "Sign in to view your profile",
            message: "See your reviews, saved lists, and account settings.",
            actionTitle: "Sign In"
        ) {
            authGate?.require {}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBackground)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            Spacer()

            NavigationLink(value: SettingsRoute()) {
                icon("gearshape")
            }
            .accessibilityLabel("Settings")

            Menu{
                Button("Edit profile") { showEditProfile = true }
                    .disabled(viewModel.profile == nil)
            } label: {
                icon("ellipsis")
            }
            .accessibilityLabel("More")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.sBackground)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.sTextPrimary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

}

// MARK: - Routes

/// Route token for pushing the Settings page from the gear button.
private struct SettingsRoute: Hashable {}

// MARK: - Preview

#Preview("Profile Screen") {
    ProfileScreen(viewModel: ProfileViewModel(userService: MockUserService()))
        .environment(AuthService.shared)
}
