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
                    onBack: { dismiss() },
                    showsClearButton: true,
                    autoFocus: true
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
        VStack(alignment: .leading, spacing: Spacing.xl) {
            spots
            places
        }
        .padding(.top, Spacing.sm)
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
        Task {
            defer { isResolving = false }
            if let place = await viewModel.selectPlace(completion) {
                onSelectPlace(place)
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview("Search") {
    NavigationStack {
        SearchScreen(onSelectPlace: { _ in }, onSelectSpot: { _ in })
    }
}
