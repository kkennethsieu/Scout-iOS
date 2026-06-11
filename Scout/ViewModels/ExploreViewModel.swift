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
    /// More pages are available — drives the "load more" trigger / footer spinner.
    private(set) var hasMore = false
    /// A `loadMore()` fetch is in flight (distinct from the initial `loading`).
    private(set) var isLoadingMore = false
    var selectedFilter: String = ExploreViewModel.filters[0]
    var filters = SpotFilters()
    var sort: SpotSort = .scout

    /// The region the feed is currently scoped to (a place picked in Search);
    /// `nil` is the default query window. `placeName` labels the clearable chip.
    private(set) var region: SpotRegion?
    private(set) var placeName: String?

    /// Static category chips for now; will come from the backend later.
    static let filters = ["All Spots", "Forest", "Coast", "Golden Hour"]

    /// Cursor for the *next* page; `nil` once the list is fully loaded.
    private var cursor: String?

    // MARK: - Dependencies

    private let service: SpotService
    private let pageSize = 20

    init(service: SpotService = AppServices.spot) {
        self.service = service
    }

    // MARK: - Derived

    var filteredSpots: [SpotSummary] {
        let matched = spots.filter { filters.matches($0) }
        return sort.sorted(matched, distance: distance(for:))
    }

    var spotCountText: String {
        let count = filteredSpots.count
        // Count reflects loaded pages; `+` signals more are available on scroll.
        return "\(count)\(hasMore ? "+" : "") spots"
    }

    /// Number of spots matching `candidate` — used by the filter sheet to preview
    /// results before they're applied.
    func resultCount(for candidate: SpotFilters) -> Int {
        spots.filter { candidate.matches($0) }.count
    }

    // MARK: - Actions

    func load() async {
        state = .loading
        cursor = nil
        do {
            let page = try await service.fetchSpots(near: region, limit: pageSize, cursor: nil)
            spots = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Scopes the feed to a place picked in Search and reloads from page one.
    func showPlace(_ region: SpotRegion, name: String) async {
        self.region = region
        placeName = name
        await load()
    }

    /// Clears the place scope and reloads the default feed.
    func clearPlace() async {
        region = nil
        placeName = nil
        await load()
    }

    /// Appends the next page. No-ops unless the list is loaded, more pages exist,
    /// and no fetch is already running. On failure the list is left intact and the
    /// cursor is preserved, so the next trigger retries.
    func loadMore() async {
        guard state == .loaded, hasMore, !isLoadingMore, let cursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.fetchSpots(near: region, limit: pageSize, cursor: cursor)
            spots.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep the loaded spots; a later trigger will retry this page.
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
