import SwiftUI
import MapKit
import Observation

/// Drives the dedicated SearchScreen. The screen is a **place** search: as the
/// user types, `PlaceSearch` (MapKit) returns autocomplete suggestions; tapping
/// one resolves it to a `SpotRegion` that re-drives the Explore feed. When the
/// query is empty it surfaces `recentSearches`, the app's only persisted state.
@Observable
@MainActor
final class SearchViewModel {

    // MARK: - State

    var query: String = "" {
        didSet {
            places.updateQuery(query)
            scheduleSpotSearch()
        }
    }
    private(set) var recentSearches: [String] = []

    /// Backend name matches (the "Spots" section). Tapping one opens Spot Detail.
    private(set) var spotResults: [SpotSummary] = []
    /// A backend spot search is scheduled or in flight — drives the loading skeleton.
    private(set) var isSearchingSpots = false

    /// MapKit autocomplete. Owned here so `query` drives it directly.
    let places = PlaceSearch()

    var placeResults: [MKLocalSearchCompletion] { places.completions }

    /// Any results to show (either section). When false with no search in flight,
    /// the screen shows its empty state.
    var hasResults: Bool { !spotResults.isEmpty || !placeResults.isEmpty }

    /// Most recent searches kept; oldest fall off the end.
    private let recentsLimit = 8
    private let recentsKey = "scout.recentSearches"

    /// Backend search tuning. `minQueryLength` matches the endpoint's `q` minimum.
    private let minQueryLength = 2
    private let spotLimit = 5
    private let searchDebounce: Duration = .milliseconds(300)
    private var searchTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let service: SpotService
    private let defaults: UserDefaults

    init(service: SpotService = AppServices.spot, defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
        self.recentSearches = loadRecents()
    }

    /// Biases autocomplete relevance toward the user's location.
    func biasPlaceResults(around coordinate: CLLocationCoordinate2D) {
        places.bias(around: coordinate)
    }

    // MARK: - Spot search

    /// Debounces a backend name search. Clears results below the min length so the
    /// Spots section disappears as the user deletes back down.
    private func scheduleSpotSearch() {
        searchTask?.cancel()
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= minQueryLength else {
            spotResults = []
            isSearchingSpots = false
            return
        }
        isSearchingSpots = true
        searchTask = Task { [weak self, searchDebounce] in
            try? await Task.sleep(for: searchDebounce)
            guard !Task.isCancelled else { return }
            await self?.performSpotSearch(q)
        }
    }

    /// Runs the backend name search now. Internal so tests can drive it without
    /// the debounce. On failure it keeps prior results (transient-tolerant).
    /// A superseded (cancelled) call leaves `isSearchingSpots` for the newer task.
    func performSpotSearch(_ rawQuery: String) async {
        let q = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= minQueryLength else {
            spotResults = []
            isSearchingSpots = false
            return
        }
        do {
            let results = try await service.searchSpots(query: q, limit: spotLimit)
            guard !Task.isCancelled else { return }
            spotResults = results
            isSearchingSpots = false
        } catch {
            // Keep prior results; a later keystroke retries.
            guard !Task.isCancelled else { return }
            isSearchingSpots = false
        }
    }

    // MARK: - Place selection

    /// Resolves a tapped suggestion to a place + region and records it in recents.
    /// Returns `nil` if MapKit couldn't resolve it.
    func selectPlace(_ completion: MKLocalSearchCompletion) async -> ResolvedPlace? {
        do {
            let place = try await places.resolve(completion)
            commitSearch(completion.title)
            return place
        } catch {
            return nil
        }
    }

    // MARK: - Recent searches

    /// Records a term at the top of the recents list (case-insensitive dedupe,
    /// capped). Blank terms are ignored.
    func commitSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        if updated.count > recentsLimit {
            updated = Array(updated.prefix(recentsLimit))
        }
        recentSearches = updated
        saveRecents()
    }

    /// Re-runs a recent search by dropping it back into the query field (which
    /// triggers autocomplete via `query`'s `didSet`).
    func selectRecent(_ term: String) {
        query = term
    }

    func clearRecents() {
        recentSearches = []
        saveRecents()
    }

    // MARK: - Persistence

    private func loadRecents() -> [String] {
        guard let data = defaults.data(forKey: recentsKey),
              let terms = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return terms
    }

    private func saveRecents() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            defaults.set(data, forKey: recentsKey)
        }
    }
}
