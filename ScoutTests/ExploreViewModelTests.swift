import Testing
import Foundation
import CoreLocation
@testable import Scout

/// A SpotService stub returning a fixed list, so view-model tests don't depend
/// on the mock's artificial latency or sample contents.
private struct StubSpotService: SpotService {
    var spots: [SpotSummary] = []
    var detail: SpotDetail = .sample
    var reviews: [Review] = []
    var isFallback = false
    var error: Error?

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        if let error { throw error }
        // Paginate `spots` by integer-offset cursor so single-page tests see the
        // whole list (nextCursor == nil) while loadMore tests can page through.
        let start = cursor.flatMap(Int.init) ?? 0
        let slice = Array(spots.dropFirst(start).prefix(limit))
        let end = start + slice.count
        let next = end < spots.count ? String(end) : nil
        return PaginatedSpots(items: slice, limit: limit, nextCursor: next, isFallback: isFallback)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail {
        if let error { throw error }
        return detail
    }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        if let error { throw error }
        return PaginatedReviews(items: reviews, limit: limit, nextCursor: nil)
    }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        if let error { throw error }
        return PaginatedReviews(items: reviews, limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review {
        if let error { throw error }
        return reviews.first ?? Review.samples[0]
    }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        if let error { throw error }
        return CreatedSpotReview(spot: detail, review: reviews.first ?? Review.samples[0])
    }
}

private struct StubError: LocalizedError {
    var errorDescription: String? { "stub failure" }
}

/// Reference-type stub that records the `near:` region it was last asked to
/// fetch, so we can assert the place region is forwarded to the service.
private final class RecordingSpotService: SpotService, @unchecked Sendable {
    var spots: [SpotSummary] = []
    private(set) var lastRegion: SpotRegion?

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        lastRegion = region
        return PaginatedSpots(items: spots, limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { Review.samples[0] }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

@MainActor
struct ExploreViewModelTests {

    @Test func loadPopulatesSpotsAndMarksLoaded() async {
        let service = StubSpotService(spots: [.sample(id: "1"), .sample(id: "2")])
        let vm = ExploreViewModel(service: service)

        await vm.load()

        #expect(vm.state == .loaded)
        #expect(vm.spots.count == 2)
    }

    @Test func loadFailureSetsFailedState() async {
        let service = StubSpotService(error: StubError())
        let vm = ExploreViewModel(service: service)

        await vm.load()

        #expect(vm.state == .failed("stub failure"))
        #expect(vm.spots.isEmpty)
    }


    @Test func mostPopularSortOrdersByReviewCountDescending() async {
        let service = StubSpotService(spots: [
            .sample(id: "1", reviewCount: 57),
            .sample(id: "2", reviewCount: 342),
            .sample(id: "3", reviewCount: 128)
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.sort = .mostPopular

        #expect(vm.filteredSpots.map(\.reviewCount) == [342, 128, 57])
    }

    @Test func scoutSortPreservesServerOrder() async {
        let service = StubSpotService(spots: [
            .sample(id: "1", reviewCount: 57),
            .sample(id: "2", reviewCount: 342),
            .sample(id: "3", reviewCount: 128)
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.sort = .scout

        #expect(vm.filteredSpots.map(\.id) == ["1", "2", "3"])
    }

    @Test func closestSortOrdersByAscendingRealDistance() async {
        // Distinct coordinates increasingly far from the user (in San Francisco).
        let service = StubSpotService(spots: [
            .sample(id: "far", lat: 37.90, lng: -122.40),
            .sample(id: "near", lat: 37.775, lng: -122.418),
            .sample(id: "mid", lat: 37.80, lng: -122.42)
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()
        vm.userCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        vm.sort = .closest

        #expect(vm.filteredSpots.map(\.id) == ["near", "mid", "far"])
    }

    @Test func closestSortKeepsServerOrderWithoutLocation() async {
        let service = StubSpotService(spots: [
            .sample(id: "1", lat: 37.90, lng: -122.40),
            .sample(id: "2", lat: 37.775, lng: -122.418),
            .sample(id: "3", lat: 37.80, lng: -122.42)
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.sort = .closest   // no userCoordinate → all equal → stable server order

        #expect(vm.filteredSpots.map(\.id) == ["1", "2", "3"])
    }

    @Test func spotCountTextShowsPlusWhenMorePages() async {
        // 25 spots > pageSize (20) → first page loaded, more available.
        let many = (0..<25).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: many))
        await vm.load()

        #expect(vm.spotCountText == "20+ spots")
    }

    @Test func spotCountTextHasNoPlusOnLastPage() async {
        let few = (0..<3).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: few))
        await vm.load()

        #expect(vm.spotCountText == "3 spots")
    }

    // MARK: - Fallback

    @Test func fallbackResponseSetsFlagAndBannerText() async {
        let service = StubSpotService(spots: [.sample(id: "1")], isFallback: true)
        let vm = ExploreViewModel(service: service)

        await vm.load()

        #expect(vm.isFallback)
        #expect(vm.fallbackBannerText?.contains("popular spots") == true)
    }

    @Test func nonFallbackResponseHasNoBanner() async {
        let service = StubSpotService(spots: [.sample(id: "1")])
        let vm = ExploreViewModel(service: service)

        await vm.load()

        #expect(!vm.isFallback)
        #expect(vm.fallbackBannerText == nil)
    }

    // MARK: - Pagination

    @Test func loadFetchesFirstPageAndFlagsMore() async {
        let many = (0..<25).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: many))

        await vm.load()

        #expect(vm.spots.count == 20)
        #expect(vm.hasMore)
    }

    @Test func loadMoreAppendsNextPageAndClearsMore() async {
        let many = (0..<25).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: many))
        await vm.load()

        await vm.loadMore()

        #expect(vm.spots.count == 25)
        #expect(!vm.hasMore)
    }

    @Test func loadMoreIsNoOpOnLastPage() async {
        let few = (0..<3).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: few))
        await vm.load()

        await vm.loadMore()

        #expect(vm.spots.count == 3)
        #expect(!vm.hasMore)
    }

    @Test func loadMoreIsNoOpBeforeInitialLoad() async {
        let many = (0..<25).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: many))

        await vm.loadMore()

        #expect(vm.spots.isEmpty)
        #expect(!vm.hasMore)
    }

    @Test func distanceTextNilWithoutLocationAndSetWithIt() {
        let vm = ExploreViewModel(service: StubSpotService())
        let spot = SpotSummary.sample(id: "x", lat: 37.80, lng: -122.42)

        #expect(vm.distanceText(for: spot) == nil)

        vm.userCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        #expect(vm.distanceText(for: spot)?.hasSuffix("mi") == true)
    }

    // MARK: - User location centering

    @Test func applyUserLocationCentersFeedWhenNoPlace() async {
        let service = RecordingSpotService()
        let vm = ExploreViewModel(service: service)

        await vm.applyUserLocation(CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))

        #expect(vm.userCoordinate != nil)
        #expect(vm.region == nil)
        #expect(service.lastRegion?.latitude == 37.7749)   // queried around the user
    }

    @Test func applyUserLocationDoesNotOverridePlace() async {
        let service = RecordingSpotService()
        let vm = ExploreViewModel(service: service)
        let place = SpotRegion(latitude: 37.86, longitude: -119.53, radiusKm: 40)
        await vm.showPlace(place, name: "Yosemite National Park")

        await vm.applyUserLocation(CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))

        #expect(service.lastRegion == place)   // still the place, not the user
    }

    @Test func applyUserLocationNilLeavesDefaultWindow() async {
        let service = RecordingSpotService()
        let vm = ExploreViewModel(service: service)
        await vm.load()

        await vm.applyUserLocation(nil)

        #expect(service.lastRegion == nil)   // LA fallback in the service
    }

    // MARK: - Place scope

    @Test func showPlaceSetsScopeForwardsRegionAndReloads() async {
        let service = RecordingSpotService()
        service.spots = [.sample(id: "1")]
        let vm = ExploreViewModel(service: service)
        let region = SpotRegion(latitude: 37.86, longitude: -119.53, radiusKm: 40)

        await vm.showPlace(region, name: "Yosemite National Park")

        #expect(vm.region == region)
        #expect(vm.placeName == "Yosemite National Park")
        #expect(vm.state == .loaded)
        #expect(service.lastRegion == region)
    }

    @Test func clearPlaceResetsScopeAndReloadsDefault() async {
        let service = RecordingSpotService()
        let vm = ExploreViewModel(service: service)
        await vm.showPlace(SpotRegion(latitude: 1, longitude: 2, radiusKm: 3), name: "Somewhere")

        await vm.clearPlace()

        #expect(vm.region == nil)
        #expect(vm.placeName == nil)
        #expect(service.lastRegion == nil)
    }
}

@MainActor
struct SpotDetailViewModelTests {

    @Test func loadPopulatesDetailAndReviews() async {
        let service = StubSpotService(detail: .sample, reviews: Review.samples)
        let vm = SpotDetailViewModel(spotID: "1", service: service)

        await vm.load()

        #expect(vm.state == .loaded)
        #expect(vm.detail?.name == "The Emerald Basin")
        #expect(vm.reviews.count == Review.samples.count)
    }

    @Test func loadFailureSetsFailedState() async {
        let vm = SpotDetailViewModel(spotID: "1", service: StubSpotService(error: StubError()))

        await vm.load()

        #expect(vm.state == .failed("stub failure"))
        #expect(vm.detail == nil)
    }

    @Test func reviewCountTextUsesDetailCount() async {
        let vm = SpotDetailViewModel(spotID: "1", service: StubSpotService(detail: .sample))
        await vm.load()

        #expect(vm.reviewCountText == "128 people shared their view")
    }
}
