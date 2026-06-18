import SwiftUI
import CoreLocation

struct ExploreScreen: View {
    @State private var viewModel: ExploreViewModel
    @State private var location = LocationManager()
    @Environment(SavedStore.self) private var savedStore: SavedStore?
    @State private var saveTarget: SpotSummary?
    @State private var showFilters = false
    @State private var showSort = false
    @State private var path = NavigationPath()

    init(service: SpotService = AppServices.spot) {
        _viewModel = State(initialValue: ExploreViewModel(service: service))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                Color.sBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        SSearchBar(
                            text: .constant(""),
                            placeholder: "Search places...",
                            activeFilterCount: viewModel.filters.activeCount,
                            onTapFilter: { showFilters = true },
                            onTap: { path.append(SearchRoute()) }
                        )
                        if let placeName = viewModel.placeName {
                            HStack {
                                ExplorePlaceChip(name: placeName) {
                                    Task { await viewModel.clearPlace() }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        ExploreHeaderRow(
                            countText: viewModel.spotCountText,
                            sortLabel: viewModel.sort.label
                        ) {
                            showSort = true
                        }
                        content
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xxxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.bottom, Spacing.xxl)
            .padding(.bottom, Spacing.xl)
            .navigationDestination(for: SpotSummary.self) { spot in
                SpotDetailScreen(spotID: spot.id)
            }
            .navigationDestination(for: SearchRoute.self) { _ in
                SearchScreen { place in
                    // Place: pop search (SearchScreen dismisses itself) + re-scope feed.
                    Task { await viewModel.showPlace(place.region, name: place.name) }
                } onSelectSpot: { spot in
                    // Spot: drop search and push the spot's detail in its place.
                    var detail = NavigationPath()
                    detail.append(spot)
                    path = detail
                }
            }
            .sheet(isPresented: $showFilters) {
                ExploreFilterSheet(filters: $viewModel.filters) { candidate in
                    viewModel.resultCount(for: candidate)
                }
            }
            .sheet(isPresented: $showSort) {
                ExploreSortSheet(selection: $viewModel.sort)
            }
            .sheet(item: $saveTarget) { spot in
                SaveToListSheet(spotID: spot.id)
            }
            .task {
                location.start()   // passive — the primer handles the prompt
                await viewModel.applyUserLocation(location.coordinate)
                if viewModel.state == .idle { await viewModel.load() }
            }
            .onChange(of: location.coordinate?.latitude) { _, _ in
                Task { await viewModel.applyUserLocation(location.coordinate) }
            }
            .enableSwipeBack()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ExploreSkeleton()
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .padding(.top, Spacing.xxxl)
        case .loaded:
            if viewModel.filteredSpots.isEmpty {
                emptyState.padding(.top, Spacing.xxxl)
            } else {
                spotList
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let placeName = viewModel.placeName {
            SEmptyStateView(
                icon: "mappin.slash",
                title: "No spots in \(placeName)",
                message: "Be the first!",
                actionTitle: "Add the first spot in \(placeName)"
            ) {
                Task { await viewModel.clearPlace() }
            }
        } else if viewModel.filters.activeCount > 0 {
            SEmptyStateView(
                icon: "line.3.horizontal.decrease.circle",
                title: "No spots match your filters",
                actionTitle: "Clear filters"
            ) {
                viewModel.clearFilters()
            }
        } else {
            SEmptyStateView(
                icon: "mappin.slash",
                title: "No spots yet",
                message: "Check back soon."
            )
        }
    }

    private var spotList: some View {
        LazyVStack(spacing: Spacing.xl) {
            ForEach(viewModel.filteredSpots) { spot in
                NavigationLink(value: spot) {
                    SpotCard(
                        spot: spot,
                        distance: viewModel.distanceText(for: spot),
                        isSaved: savedStore?.isSaved(spot.id) ?? false
                    ) {
                        saveTarget = spot
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    // Reached the last card — pull the next page.
                    if spot.id == viewModel.filteredSpots.last?.id {
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
        .padding(.top, Spacing.xs)
    }

}

/// Path value that pushes the search screen onto Explore's stack.
private struct SearchRoute: Hashable {}

// MARK: - Preview

#Preview("Explore") {
    ExploreScreen(service: MockSpotService())
}

#Preview("Explore — Dark") {
    ExploreScreen(service: MockSpotService())
        .preferredColorScheme(.dark)
}
