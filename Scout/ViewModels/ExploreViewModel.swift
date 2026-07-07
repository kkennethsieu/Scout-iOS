import SwiftUI
import CoreLocation
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
    /// The backend had no spots near the query area and returned popular spots
    /// from a default region instead. Drives the fallback banner.
    private(set) var isFallback = false
    var filters = SpotFilters()
    var sort: SpotSort = .scout

    /// The region the feed is currently scoped to (a place picked in Search);
    /// `nil` is the default query window. `placeName` labels the clearable chip.
    private(set) var region: SpotRegion?
    private(set) var placeName: String?

    /// The user's location (set by the screen). Drives the default feed center and
    /// real card distances; `nil` falls back to the service's default window.
    var userCoordinate: CLLocationCoordinate2D?
    /// Re-center the feed on the user only once, when their first fix arrives.
    private var hasCenteredOnUser = false

    /// Cursor for the *next* page; `nil` once the list is fully loaded.
    private var cursor: String?

    // MARK: - Dependencies

    private let service: SpotService
    private let pageSize = 20
    private let defaultRadiusKm: Double = 50

    /// Where to query: an explicit place wins, else center on the user, else `nil`
    /// (the service falls back to its default LA window).
    private var queryRegion: SpotRegion? {
        region ?? userCoordinate.map {
            SpotRegion(latitude: $0.latitude, longitude: $0.longitude, radiusKm: defaultRadiusKm)
        }
    }

    init(service: SpotService = AppServices.spot) {
        self.service = service
    }

    // MARK: - Derived

    var filteredSpots: [SpotSummary] {
        let matched = spots.filter { filters.matches($0) }
        return sort.sorted(matched, distance: sortDistance(for:))
    }

    /// Banner copy shown when the feed is showing fallback (default-region) spots
    /// because nothing was found near the user; `nil` when not in fallback mode.
    /// The city is read from the returned spots (the backend sends no separate
    /// fallback-city field).
    var fallbackBannerText: String? {
        guard isFallback else { return nil }
        if let city = spots.first?.city, !city.isEmpty {
            return "No spots near you — here are popular spots in \(city)."
        }
        return "No spots near you — here are some popular spots instead."
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

    /// Resets all active filters (used by the empty-state CTA).
    func clearFilters() {
        filters = SpotFilters()
    }

    // MARK: - Actions

    func load() async {
        state = .loading
        cursor = nil
        do {
            let page = try await service.fetchSpots(near: queryRegion, limit: pageSize, cursor: nil)
            spots = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
            isFallback = page.isFallback
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

    /// Clears the place scope and reloads the default feed (re-centers on the user).
    func clearPlace() async {
        region = nil
        placeName = nil
        await load()
    }

    /// Adopts the user's latest coordinate. Refreshes card distances always, and
    /// re-centers the default feed once, when the first fix arrives (a place scope
    /// is never overridden).
    func applyUserLocation(_ coordinate: CLLocationCoordinate2D?) async {
        userCoordinate = coordinate
        guard coordinate != nil, region == nil, !hasCenteredOnUser else { return }
        hasCenteredOnUser = true
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
            let page = try await service.fetchSpots(near: queryRegion, limit: pageSize, cursor: cursor)
            spots.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep the loaded spots; a later trigger will retry this page.
        }
    }

    /// Real distance label from the user to `spot`, or `nil` when there's no
    /// location (the card then hides the distance).
    func distanceText(for spot: SpotSummary) -> String? {
        spot.distanceText(from: userCoordinate)
    }

    /// Sort key for `.closest`. With no location every spot sorts equal, so the
    /// stable sort preserves server order.
    private func sortDistance(for spot: SpotSummary) -> Double {
        spot.distanceMiles(from: userCoordinate) ?? .greatestFiniteMagnitude
    }
}
