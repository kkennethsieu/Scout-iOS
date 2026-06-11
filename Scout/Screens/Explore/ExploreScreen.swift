import SwiftUI

struct ExploreScreen: View {
    @State private var viewModel: ExploreViewModel
    @State private var savedSpotIDs: Set<String> = []
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
                        ExploreFilterRow(
                            filters: ExploreViewModel.filters,
                            selected: viewModel.selectedFilter
                        ) { filter in
                            viewModel.selectedFilter = filter
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

                ExplorePostButton {
                    // TODO: present create/review flow
                }
                .padding(Spacing.lg)
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
            .task {
                if viewModel.state == .idle { await viewModel.load() }
            }
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
            spotList
        }
    }

    private var spotList: some View {
        LazyVStack(spacing: Spacing.xl) {
            ForEach(viewModel.filteredSpots) { spot in
                NavigationLink(value: spot) {
                    SpotCard(
                        spot: spot,
                        distance: viewModel.distanceText(for: spot),
                        isSaved: savedSpotIDs.contains(spot.id)
                    ) {
                        toggleSave(spot)
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

    // MARK: - Actions

    private func toggleSave(_ spot: SpotSummary) {
        if savedSpotIDs.contains(spot.id) {
            savedSpotIDs.remove(spot.id)
        } else {
            savedSpotIDs.insert(spot.id)
        }
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
