import SwiftUI
import Observation

@Observable
@MainActor
final class ExploreViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    private(set) var spots: [SpotSummary] = []
    private(set) var state: LoadState = .idle
    var searchText: String = ""
    var selectedFilter: String = ExploreViewModel.filters[0]

    /// Static category chips for now; will come from the backend later.
    static let filters = ["All Spots", "Forest", "Coast", "Golden Hour"]

    // MARK: - Dependencies

    private let service: SpotService

    init(service: SpotService = MockSpotService()) {
        self.service = service
    }

    // MARK: - Derived

    var filteredSpots: [SpotSummary] {
        guard !searchText.isEmpty else { return spots }
        return spots.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var spotCountText: String {
        spots.count >= 500 ? "500+ spots" : "\(spots.count) spots"
    }

    // MARK: - Actions

    func load() async {
        state = .loading
        do {
            spots = try await service.fetchSpots()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Placeholder distance until CoreLocation is wired. Deterministic per spot
    /// so the UI doesn't flicker between renders.
    func distanceText(for spot: SpotSummary) -> String {
        let miles = Double((abs(spot.id.hashValue) % 50) + 1) / 10.0
        return "\(miles.formatted(.number.precision(.fractionLength(1)))) miles away"
    }
}
