import SwiftUI

/// The full, searchable, sortable list of a spot's reviews — pushed from the
/// Spot Detail "Reviews" section's "View All". A back / title header, a search
/// field with a sort button, the review count, then a `LazyVStack` of `ReviewCard`s.
///
/// Owns its own sortable feed (`ReviewFeedViewModel`) so changing the sort never
/// reorders the Spot Detail preview. For the default (Scout) sort the feed is
/// seeded from the shared `SpotDetailViewModel` so it shows instantly. Typing
/// runs a debounced server-side search (`ReviewSearchViewModel`); both feed and
/// search honor the selected sort.
struct ViewAllReviewsScreen: View {
    let spotName: String
    let viewModel: SpotDetailViewModel

    @State private var feed: ReviewFeedViewModel
    @State private var search: ReviewSearchViewModel
    @State private var selectedSort: ReviewSort = .scout
    @State private var showSort = false
    @Environment(\.dismiss) private var dismiss
    /// Optional so previews (which don't inject it) don't crash.
    @Environment(TabBarVisibility.self) private var tabBarVisibility: TabBarVisibility?

    init(spotName: String, viewModel: SpotDetailViewModel) {
        self.spotName = spotName
        self.viewModel = viewModel
        _feed = State(initialValue: viewModel.makeReviewFeedViewModel())
        _search = State(initialValue: viewModel.makeReviewSearchViewModel())
    }

    private var countText: String {
        if search.isActive {
            switch search.state {
            case .loading:
                return "Searching…"
            default:
                let count = search.results.count
                return "\(count) \(count == 1 ? "result" : "results")"
            }
        }
        let count = viewModel.detail?.reviewCount ?? feed.reviews.count
        return "\(count) \(count == 1 ? "Review" : "Reviews")"
    }

    var body: some View {
        ZStack {
            Color.sBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                header

                HStack(spacing: Spacing.md) {
                    SSearchBar(
                        text: $search.query,
                        placeholder: "Search reviews...",
                        showsFilter: false,
                        showsClearButton: true
                    )
                    sortButton
                }
                .padding(.horizontal, Spacing.lg)

                Text(countText)
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)

                list
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSort) {
            SSortSheet(
                title: "Sort",
                options: ReviewSort.allCases,
                selection: $selectedSort,
                label: \.label,
                icon: \.icon
            )
        }
        .onAppear { tabBarVisibility?.requestHidden() }
        .onDisappear { tabBarVisibility?.releaseHidden() }
        .task {
            guard feed.state == .idle else { return }
            // Reuse the shared feed's already-loaded default page when possible;
            // otherwise fetch the first page for the current sort.
            if selectedSort == .scout, !viewModel.reviews.isEmpty {
                feed.adopt(reviews: viewModel.reviews, cursor: viewModel.reviewsCursor, hasMore: viewModel.hasMore)
            } else {
                await feed.load(sort: selectedSort)
            }
        }
        .onChange(of: selectedSort) { _, newSort in
            Task { await feed.load(sort: newSort) }
            search.setSort(newSort)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(spotName)
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)
                .lineLimit(1)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.sTextPrimary)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var sortButton: some View {
        Button { showSort = true } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.sTextPrimary)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: Radius.pill).fill(Color.sSurface))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .stroke(Color.sBorderDefault, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sort")
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if search.isActive {
            searchResults
        } else {
            feedList
        }
    }

    // MARK: Feed (no active query)

    @ViewBuilder
    private var feedList: some View {
        switch feed.state {
        case .idle, .loading where feed.reviews.isEmpty:
            ProgressView()
                .tint(Color.sAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await feed.load(sort: selectedSort) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            if feed.reviews.isEmpty {
                SEmptyStateView(
                    icon: "text.bubble",
                    title: "No reviews yet",
                    message: "Be the first to share what this spot is like."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                reviewScroll(
                    reviews: feed.reviews,
                    isLoadingMore: feed.isLoadingMore,
                    onLastAppear: { Task { await feed.loadMore() } }
                )
            }
        }
    }

    // MARK: Search results

    @ViewBuilder
    private var searchResults: some View {
        switch search.state {
        case .idle, .loading where search.results.isEmpty:
            ProgressView()
                .tint(Color.sAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await search.performSearch(search.query) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            if search.results.isEmpty {
                SEmptyStateView(
                    icon: "magnifyingglass",
                    title: "No matching reviews",
                    message: "Try a different word from the notes, gear, or composition tips."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                reviewScroll(
                    reviews: search.results,
                    isLoadingMore: search.isLoadingMore,
                    onLastAppear: { Task { await search.loadMore() } }
                )
            }
        }
    }

    // MARK: Shared list

    /// A scrolling `LazyVStack` of review cards that pages in more when the last
    /// card appears. Shared by the feed and search-results presentations.
    private func reviewScroll(
        reviews: [Review],
        isLoadingMore: Bool,
        onLastAppear: @escaping () -> Void
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                        .onAppear {
                            if review.id == reviews.last?.id { onLastAppear() }
                        }
                }

                if isLoadingMore {
                    ProgressView()
                        .tint(Color.sAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - Preview

/// Loads a shared view model before showing the screen, mirroring how the detail
/// screen hands off an already-loaded model.
private struct ViewAllReviewsPreview: View {
    @State private var viewModel = SpotDetailViewModel(spotID: "1", service: MockSpotService())

    var body: some View {
        NavigationStack {
            ViewAllReviewsScreen(spotName: "The Emerald Basin", viewModel: viewModel)
        }
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
    }
}

#Preview("View All Reviews") {
    ViewAllReviewsPreview()
}

#Preview("View All Reviews — Dark") {
    ViewAllReviewsPreview()
        .preferredColorScheme(.dark)
}
