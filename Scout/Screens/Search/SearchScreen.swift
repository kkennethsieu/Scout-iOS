import SwiftUI
import MapKit

/// Place search pushed from the Explore search bar. Opens with the keyboard up;
/// shows Recent Searches while the field is empty and MapKit place suggestions as
/// the user types. Tapping a place resolves it to a region, hands it back via
/// `onSelectPlace`, and dismisses — Explore then re-loads its feed for that region.
///
/// Leaves the tab bar visible (it doesn't touch `TabBarVisibility`).
struct SearchScreen: View {
    @State private var viewModel = SearchViewModel()
    @State private var location = LocationManager()
    @State private var isResolving = false
    /// Owns the search field's focus so we can resign it *before* dismissing.
    /// Popping this screen while the field is still first responder orphans
    /// UIKit's full-screen editing overlay (`UIEditingOverlayGestureView`) in the
    /// text-effects window, which then swallows taps on the screen we return to.
    @FocusState private var searchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// Called with the resolved place when the user taps a place suggestion.
    let onSelectPlace: (ResolvedPlace) -> Void
    /// Called with the spot when the user taps a Spots match. Explore dismisses
    /// this screen and pushes the spot's detail in its place.
    let onSelectSpot: (SpotSummary) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.sBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                SSearchBar(
                    text: $viewModel.query,
                    placeholder: "Search places...",
                    showsFilter: false,
                    showsBackButton: true,
                    onBack: { close() },
                    showsClearButton: true,
                    autoFocus: true,
                    focus: $searchFocused
                )

                ScrollView {
                    content
                        .padding(.bottom, Spacing.xxxl)
                        .padding(.bottom, Spacing.xl)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
        }
        .toolbar(.hidden, for: .navigationBar)
        .disabled(isResolving)
        .onAppear {
            location.start()
            biasIfPossible()   // DEBUG fixed-location / already-authorized case
        }
        .onChange(of: location.coordinate?.latitude) { _, _ in
            biasIfPossible()   // async GPS fix arrived
        }
    }

    private func biasIfPossible() {
        if let coordinate = location.coordinate {
            viewModel.biasPlaceResults(around: coordinate)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            recents
        } else {
            results
        }
    }

    @ViewBuilder
    private var results: some View {
        if viewModel.hasResults {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                spots
                places
            }
            .padding(.top, Spacing.sm)
        } else if viewModel.isSearchingSpots {
            SearchSkeleton()
        } else {
            SEmptyStateView(
                icon: "magnifyingglass",
                title: "No results",
                message: "No spots or places match “\(viewModel.query)”. Try a different search."
            )
            .padding(.top, Spacing.xxxl)
        }
    }

    @ViewBuilder
    private var recents: some View {
        if viewModel.recentSearches.isEmpty {
            EmptyView()
        } else {
            SearchRecentsSection(
                recents: viewModel.recentSearches,
                onSelect: { viewModel.selectRecent($0) },
                onClearAll: { viewModel.clearRecents() }
            )
            .padding(.top, Spacing.sm)
        }
    }

    @ViewBuilder
    private var spots: some View {
        if !viewModel.spotResults.isEmpty {
            SSection(title: "Spots", titleFont: .sHeadingM) {
                LazyVStack(spacing: Spacing.lg) {
                    ForEach(viewModel.spotResults) { spot in
                        Button {
                            searchFocused = false   // resign before the screen pops
                            viewModel.commitSearch(spot.name)
                            onSelectSpot(spot)
                        } label: {
                            SpotResultRow(spot: spot, query: viewModel.query)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var places: some View {
        if !viewModel.placeResults.isEmpty {
            SSection(title: "Places", titleFont: .sHeadingM) {
                LazyVStack(spacing: Spacing.lg) {
                    ForEach(viewModel.placeResults, id: \.self) { completion in
                        Button {
                            select(completion)
                        } label: {
                            PlaceResultRow(completion: completion)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func select(_ completion: MKLocalSearchCompletion) {
        guard !isResolving else { return }
        isResolving = true
        // Resign the field now (before we pop) so UIKit tears down its editing
        // overlay cleanly; the async resolve gives it time to complete.
        searchFocused = false
        Task {
            defer { isResolving = false }
            if let place = await viewModel.selectPlace(completion) {
                onSelectPlace(place)
                dismiss()
            }
        }
    }

    /// Blurs the field before popping — see `searchFocused` for why order matters.
    private func close() {
        searchFocused = false
        dismiss()
    }
}

// MARK: - Preview

#Preview("Search") {
    NavigationStack {
        SearchScreen(onSelectPlace: { _ in }, onSelectSpot: { _ in })
    }
}
