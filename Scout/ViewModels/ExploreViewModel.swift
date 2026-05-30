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
    var filters = SpotFilters()
    var sort: SpotSort = .scout

    /// Static category chips for now; will come from the backend later.
    static let filters = ["All Spots", "Forest", "Coast", "Golden Hour"]

    // MARK: - Dependencies

    private let service: SpotService

    init(service: SpotService = AppServices.spot) {
        self.service = service
    }

    // MARK: - Derived

    var filteredSpots: [SpotSummary] {
        let matched = spots.filter { matchesSearch($0) && filters.matches($0) }
        return sort.sorted(matched, distance: distance(for:))
    }

    var spotCountText: String {
        let count = filteredSpots.count
        return count >= 500 ? "500+ spots" : "\(count) spots"
    }

    /// Number of spots matching `candidate` plus the current search — used by
    /// the filter sheet to preview results before they're applied.
    func resultCount(for candidate: SpotFilters) -> Int {
        spots.filter { matchesSearch($0) && candidate.matches($0) }.count
    }

    private func matchesSearch(_ spot: SpotSummary) -> Bool {
        guard !searchText.isEmpty else { return true }
        return spot.name.localizedCaseInsensitiveContains(searchText)
            || spot.city.localizedCaseInsensitiveContains(searchText)
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

    /// Placeholder distance in miles until CoreLocation is wired. Deterministic
    /// per spot so the UI doesn't flicker between renders.
    func distance(for spot: SpotSummary) -> Double {
        Double((abs(spot.id.hashValue) % 50) + 1) / 10.0
    }

    func distanceText(for spot: SpotSummary) -> String {
        let miles = distance(for: spot).formatted(.number.precision(.fractionLength(1)))
        return "\(miles) miles away"
    }
}
