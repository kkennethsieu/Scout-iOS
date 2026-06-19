import Testing
import Foundation
@testable import Scout

/// Covers `ReviewFeedViewModel` pagination + sort forwarding, and the
/// `ReviewSort` → backend value mapping.
@MainActor
struct ReviewFeedViewModelTests {

    @Test func loadPopulatesFirstPageAndFlagsMore() async {
        let vm = ReviewFeedViewModel(spotID: "s1", service: twoPageService)
        await vm.load(sort: .newest)
        #expect(vm.state == .loaded)
        #expect(vm.reviews.map(\.id) == ["r1"])
        #expect(vm.hasMore)
        #expect(vm.sort == .newest)
    }

    @Test func loadMoreAppendsAndEnds() async {
        let vm = ReviewFeedViewModel(spotID: "s1", service: twoPageService)
        await vm.load(sort: .newest)
        await vm.loadMore()
        #expect(vm.reviews.map(\.id) == ["r1", "r2"])
        #expect(!vm.hasMore)
    }

    @Test func loadForwardsSortApiValue() async {
        let service = RecordingFeedService()
        let vm = ReviewFeedViewModel(spotID: "s1", service: service)
        await vm.load(sort: .highestRated)
        #expect(service.lastSort == "highest_rated")
    }

    @Test func loadSurfacesFailures() async {
        let vm = ReviewFeedViewModel(spotID: "s1", service: FailingFeedService())
        await vm.load(sort: .scout)
        #expect(vm.state == .failed("boom"))
        #expect(vm.reviews.isEmpty)
    }

    @Test func adoptSeedsWithoutFetching() async {
        let service = RecordingFeedService()
        let vm = ReviewFeedViewModel(spotID: "s1", service: service)
        vm.adopt(reviews: [Review.samples[0]], cursor: "p2", hasMore: true)
        #expect(vm.state == .loaded)
        #expect(vm.reviews.map(\.id) == ["r1"])
        #expect(vm.hasMore)
        #expect(vm.sort == .scout)
        #expect(service.lastSort == nil)   // no network call
    }

    @Test func reviewSortMapsToBackendValues() {
        #expect(ReviewSort.scout.apiValue == "scout")
        #expect(ReviewSort.newest.apiValue == "newest")
        #expect(ReviewSort.highestRated.apiValue == "highest_rated")
        #expect(ReviewSort.lowestRated.apiValue == "lowest_rated")
        // Display order matches the sheet (Scout Sort first).
        #expect(ReviewSort.allCases.first == .scout)
    }

    // MARK: - Stubs

    private var twoPageService: TwoPageFeedService {
        TwoPageFeedService(page1: [Review.samples[0]], page2: [Review.samples[1]])
    }
}

/// Returns two fixed pages: page one (cursor `nil`) hands back `"p2"`; page two ends.
private struct TwoPageFeedService: SpotService {
    let page1: [Review]
    let page2: [Review]

    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        switch cursor {
        case nil: return PaginatedReviews(items: page1, limit: limit, nextCursor: "p2")
        default:  return PaginatedReviews(items: page2, limit: limit, nextCursor: nil)
        }
    }

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

/// Records the last `sort` the feed asked for, so we can assert forwarding.
private final class RecordingFeedService: SpotService, @unchecked Sendable {
    private(set) var lastSort: String?

    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        lastSort = sort
        return PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

private struct FailingFeedService: SpotService {
    struct Boom: Error, LocalizedError { var errorDescription: String? { "boom" } }

    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        throw Boom()
    }

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}
