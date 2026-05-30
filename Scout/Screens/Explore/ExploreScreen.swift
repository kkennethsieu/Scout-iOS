import SwiftUI

struct ExploreScreen: View {
    @State private var viewModel: ExploreViewModel
    @State private var savedSpotIDs: Set<String> = []
    @State private var showFilters = false
    @State private var showSort = false

    init(service: SpotService = AppServices.spot) {
        _viewModel = State(initialValue: ExploreViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.sBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        SSearchBar(
                            text: $viewModel.searchText,
                            activeFilterCount: viewModel.filters.activeCount
                        ) {
                            showFilters = true
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
            .navigationDestination(for: SpotSummary.self) { spot in
                SpotDetailScreen(spotID: spot.id)
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
            SLoadingState()
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

// MARK: - Preview

#Preview("Explore") {
    ExploreScreen(service: MockSpotService())
}

#Preview("Explore — Dark") {
    ExploreScreen(service: MockSpotService())
        .preferredColorScheme(.dark)
}
