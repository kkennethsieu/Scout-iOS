import SwiftUI

/// The Profile root: a custom top bar (settings + more), the user header, a
/// Photos/Reviews segmented control, and the selected tab's content. No data
/// wiring yet — the view model serves sample content.
struct ProfileScreen: View {
    @State private var viewModel: ProfileViewModel
    @Environment(AuthService.self) private var auth

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
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeader(profile: viewModel.profile)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.sm)

                    SSegmentedControl(
                        options: ProfileViewModel.Tab.allCases,
                        selection: $viewModel.selectedTab,
                        label: \.title
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                    tabContent
                        .padding(Spacing.lg)
                }
            }
            .background(Color.sBackground)
            .refreshable { await viewModel.load() }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
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
        }
        .task(id: isActive) {
            // Refetch whenever the Profile tab becomes the active one.
            if isActive { await viewModel.load() }
        }
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

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .photos:
            ProfilePhotoGrid(photoURLs: viewModel.photoURLs)
        case .reviews:
            ProfileReviewsList(viewModel: viewModel)
        }
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
