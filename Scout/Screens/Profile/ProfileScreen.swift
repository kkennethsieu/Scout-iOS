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

    init(isActive: Bool = true, viewModel: ProfileViewModel = ProfileViewModel()) {
        self.isActive = isActive
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
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
        .safeAreaInset(edge: .top, spacing:0){ topBar }
        .refreshable { await viewModel.load() }
        .task(id: isActive) {
            // Refetch whenever the Profile tab becomes the active one.
            if isActive { await viewModel.load() }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            Spacer()

            Menu {
                Button("Sign out", role: .destructive) {
                    try? auth.signOut()
                }
            } label: {
                icon("gearshape")
            }
            .accessibilityLabel("Settings")

            // Stubbed — "more" actions land here once wired.
            Button {} label: {
                icon("ellipsis")
            }
            .buttonStyle(.plain)
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
            if viewModel.photoURLs.isEmpty {
                emptyState(icon: "photo.on.rectangle.angled", message: "No photos yet")
            } else {
                ProfilePhotoGrid(photoURLs: viewModel.photoURLs)
            }
        case .reviews:
            reviewsContent
        }
    }

    @ViewBuilder
    private var reviewsContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            SLoadingState()
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        case .loaded:
            if viewModel.reviews.isEmpty {
                emptyState(icon: "star", message: "No reviews yet")
            } else {
                reviewsList
            }
        }
    }

    private var reviewsList: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(viewModel.reviews) { review in
                ProfileReviewCard(review: review)
                    .onAppear {
                        // Reached the last card — pull the next page.
                        if review.id == viewModel.reviews.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .tint(Color.sAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.sTextTertiary)
            Text(message)
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Preview

#Preview("Profile Screen") {
    ProfileScreen(viewModel: ProfileViewModel(userService: MockUserService()))
        .environment(AuthService.shared)
}
