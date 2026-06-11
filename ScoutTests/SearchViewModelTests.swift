import Testing
import Foundation
@testable import Scout

/// Fresh, isolated UserDefaults per test so recents don't leak between runs.
private func makeDefaults() -> UserDefaults {
    let suite = "SearchViewModelTests.\(UUID().uuidString)"
    return UserDefaults(suiteName: suite)!
}

/// Stub returning fixed name-search results, capped by `limit` like the backend.
private struct StubSpotService: SpotService {
    var searchResults: [SpotSummary] = []

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] {
        Array(searchResults.prefix(limit))
    }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String) async throws -> [Review] { [] }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

@MainActor
struct SearchViewModelTests {

    // MARK: - Spot search

    @Test func performSpotSearchPopulatesResults() async {
        let service = StubSpotService(searchResults: [.sample(id: "1", name: "Cedar Cathedral")])
        let vm = SearchViewModel(service: service, defaults: makeDefaults())

        await vm.performSpotSearch("cedar")

        #expect(vm.spotResults.map(\.id) == ["1"])
        #expect(vm.hasResults)
        #expect(!vm.isSearchingSpots)
    }

    @Test func performSpotSearchIgnoresShortQueries() async {
        let service = StubSpotService(searchResults: [.sample(id: "1")])
        let vm = SearchViewModel(service: service, defaults: makeDefaults())

        await vm.performSpotSearch("c")

        #expect(vm.spotResults.isEmpty)
        #expect(!vm.isSearchingSpots)
    }

    @Test func hasResultsFalseWhenEmpty() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())

        #expect(!vm.hasResults)
    }

    // MARK: - Recent searches
    //
    // The place-autocomplete path runs through MapKit (network) and isn't
    // unit-tested here; recents are the testable, persisted state.

    @Test func commitSearchInsertsNewestFirstAndTrims() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())

        vm.commitSearch("  Big Sur  ")
        vm.commitSearch("Yosemite")

        #expect(vm.recentSearches == ["Yosemite", "Big Sur"])
    }

    @Test func commitSearchIgnoresBlank() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())

        vm.commitSearch("   ")

        #expect(vm.recentSearches.isEmpty)
    }

    @Test func commitSearchDedupesCaseInsensitivelyMovingToFront() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())

        vm.commitSearch("Big Sur")
        vm.commitSearch("Yosemite")
        vm.commitSearch("big sur")

        #expect(vm.recentSearches == ["big sur", "Yosemite"])
    }

    @Test func commitSearchCapsAtEight() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())

        for i in 0..<10 { vm.commitSearch("term \(i)") }

        #expect(vm.recentSearches.count == 8)
        #expect(vm.recentSearches.first == "term 9")
        #expect(vm.recentSearches.last == "term 2")
    }

    @Test func clearRecentsEmptiesList() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())
        vm.commitSearch("Big Sur")

        vm.clearRecents()

        #expect(vm.recentSearches.isEmpty)
    }

    @Test func selectRecentSetsQuery() {
        let vm = SearchViewModel(service: StubSpotService(), defaults: makeDefaults())

        vm.selectRecent("Joshua Tree")

        #expect(vm.query == "Joshua Tree")
    }

    @Test func recentsPersistAcrossViewModelInstances() {
        let defaults = makeDefaults()
        let first = SearchViewModel(service: StubSpotService(), defaults: defaults)
        first.commitSearch("Big Sur")
        first.commitSearch("Yosemite")

        let second = SearchViewModel(service: StubSpotService(), defaults: defaults)

        #expect(second.recentSearches == ["Yosemite", "Big Sur"])
    }
}
