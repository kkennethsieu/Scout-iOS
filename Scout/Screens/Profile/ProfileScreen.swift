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

    /// The review the user tapped "Delete" on; presenting the confirmation dialog.
    @State private var reviewPendingDeletion: Review?

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
        }
        .task(id: isActive) {
            // Refetch whenever the Profile tab becomes the active one.
            if isActive { await viewModel.load() }
        }
        .confirmationDialog(
            "Delete this review?",
            isPresented: Binding(
                get: { reviewPendingDeletion != nil },
                set: { if !$0 { reviewPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: reviewPendingDeletion
        ) { review in
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteReview(review) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { review in
            Text("This permanently removes your review\(review.spotName.map { " of \($0)" } ?? "").")
        }
        .alert(
            "Couldn't delete review",
            isPresented: Binding(
                get: { viewModel.deleteError != nil },
                set: { if !$0 { viewModel.dismissDeleteError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.deleteError ?? "")
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
                SEmptyStateView(icon: "photo.on.rectangle.angled", title: "No photos yet")
                    .padding(.vertical, Spacing.xxl)
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
                SEmptyStateView(icon: "star", title: "No reviews yet")
                    .padding(.vertical, Spacing.xxl)
            } else {
                reviewsList
            }
        }
    }

    private var reviewsList: some View {
        // Lazy so off-screen cards aren't realized up front — otherwise the last
        // card's `.onAppear` fires immediately (and again after each appended
        // page), cascading several `loadMore()` calls without any scrolling.
        LazyVStack(spacing: Spacing.lg) {
            ForEach(viewModel.reviews) { review in
                ProfileReviewCard(
                    review: review,
                    isDeleting: viewModel.deletingReviewID == review.id,
                    onDelete: { reviewPendingDeletion = review }
                )
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

}

// MARK: - Preview

#Preview("Profile Screen") {
    ProfileScreen(viewModel: ProfileViewModel(userService: MockUserService()))
        .environment(AuthService.shared)
}
