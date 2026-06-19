import Testing
import Foundation
@testable import Scout

/// Covers `ReviewSearchViewModel`'s search + pagination. `performSearch` and
/// `loadMore` are driven directly (bypassing the debounce, which is exercised
/// implicitly through the `query` setter elsewhere).
@MainActor
struct ReviewSearchViewModelTests {

    @Test func performSearchPopulatesResultsAndFlagsMore() async {
        let vm = ReviewSearchViewModel(spotID: "s1", service: twoPageService)
        await vm.performSearch("basin")
        #expect(vm.state == .loaded)
        #expect(vm.results.map(\.id) == ["r1"])
        #expect(vm.hasMore)
    }

    @Test func loadMoreAppendsAndEnds() async {
        let vm = ReviewSearchViewModel(spotID: "s1", service: twoPageService)
        await vm.performSearch("basin")
        await vm.loadMore()
        #expect(vm.results.map(\.id) == ["r1", "r2"])
        #expect(!vm.hasMore)
    }

    @Test func queryBelowMinLengthClearsAndStaysIdle() async {
        let vm = ReviewSearchViewModel(spotID: "s1", service: twoPageService)
        await vm.performSearch("basin")
        #expect(vm.state == .loaded)

        // A single character is below the endpoint's 2-char minimum.
        await vm.performSearch("b")
        #expect(vm.state == .idle)
        #expect(vm.results.isEmpty)
    }

    @Test func searchFailureSurfacesError() async {
        let vm = ReviewSearchViewModel(spotID: "s1", service: FailingSearchService())
        await vm.performSearch("basin")
        #expect(vm.state == .failed("boom"))
        #expect(vm.results.isEmpty)
    }

    @Test func shortQueryNeverHitsBackend() async throws {
        let service = CountingSearchService()
        let vm = ReviewSearchViewModel(spotID: "s1", service: service)

        // Two characters is below the client minimum, so no fetch is scheduled.
        vm.query = "ba"
        try await Task.sleep(for: debounceWindow)
        #expect(service.searchCount == 0)
        #expect(vm.state == .idle)
    }

    @Test func unchangedQueryIsNotRefetched() async throws {
        let service = CountingSearchService()
        let vm = ReviewSearchViewModel(spotID: "s1", service: service)

        vm.query = "basin"
        try await Task.sleep(for: debounceWindow)
        #expect(service.searchCount == 1)

        // Trailing whitespace leaves the effective query unchanged — no re-hit.
        vm.query = "basin "
        try await Task.sleep(for: debounceWindow)
        #expect(service.searchCount == 1)

        // A genuinely different query fetches again.
        vm.query = "ridge"
        try await Task.sleep(for: debounceWindow)
        #expect(service.searchCount == 2)
    }

    // MARK: - Stubs

    /// Comfortably longer than the 300ms debounce so the scheduled fetch fires.
    private let debounceWindow: Duration = .milliseconds(500)

    private var twoPageService: TwoPageReviewSearchService {
        TwoPageReviewSearchService(page1: [Review.samples[0]], page2: [Review.samples[1]])
    }
}

/// Returns two fixed pages: page one (cursor `nil`) hands back `"p2"`; page two ends.
private struct TwoPageReviewSearchService: SpotService {
    let page1: [Review]
    let page2: [Review]

    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        switch cursor {
        case nil: return PaginatedReviews(items: page1, limit: limit, nextCursor: "p2")
        default:  return PaginatedReviews(items: page2, limit: limit, nextCursor: nil)
        }
    }

    // Unused by these tests.
    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

/// Counts how many times the search endpoint is hit, so we can assert the
/// debounce + dedup don't fire redundant requests.
private final class CountingSearchService: SpotService, @unchecked Sendable {
    private(set) var searchCount = 0

    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        searchCount += 1
        return PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

private struct FailingSearchService: SpotService {
    struct Boom: Error, LocalizedError { var errorDescription: String? { "boom" } }

    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        throw Boom()
    }

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}
