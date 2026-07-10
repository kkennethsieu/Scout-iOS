import Testing
import Foundation
import CoreLocation
@testable import Scout

/// Reference-type stub that records the `near:` region of each spots fetch and how
/// many fetches ran, so we can assert the Map queries around the user and reloads
/// only on the first fix.
private final class RecordingSpotService: SpotService, @unchecked Sendable {
    var spots: [SpotSummary] = []
    var isFallback = false
    private(set) var lastRegion: SpotRegion?
    private(set) var fetchCount = 0

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        lastRegion = region
        fetchCount += 1
        return PaginatedSpots(items: spots, limit: limit, nextCursor: nil, isFallback: isFallback)
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
struct MapViewModelTests {

    @Test func loadWithoutLocationUsesDefaultWindow() async {
        let service = RecordingSpotService()
        let vm = MapViewModel(service: service)

        await vm.load()

        #expect(vm.state == .loaded)
        #expect(service.lastRegion == nil)   // LA fallback in the service
    }

    @Test func applyUserLocationQueriesNearUserAndCenters() async {
        let service = RecordingSpotService()
        service.spots = [.sample(id: "1")]
        let vm = MapViewModel(service: service)

        await vm.applyUserLocation(CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))

        #expect(vm.userCoordinate?.latitude == 37.7749)
        #expect(vm.state == .loaded)
        #expect(service.lastRegion?.latitude == 37.7749)   // queried around the user
    }

    @Test func secondFixDoesNotReload() async {
        let service = RecordingSpotService()
        let vm = MapViewModel(service: service)

        await vm.applyUserLocation(CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        let afterFirst = service.fetchCount
        await vm.applyUserLocation(CLLocationCoordinate2D(latitude: 40.71, longitude: -74.00))

        #expect(service.fetchCount == afterFirst)            // no extra reload
        #expect(vm.userCoordinate?.latitude == 40.71)        // but coordinate updates
    }

    // MARK: - Fallback

    @Test func fallbackLoadSetsFlagAndBannerText() async {
        let service = RecordingSpotService()
        service.spots = [.sample(id: "1")]
        service.isFallback = true
        let vm = MapViewModel(service: service)

        await vm.load()

        #expect(vm.isFallback)
        #expect(vm.fallbackBannerText?.contains("popular spots") == true)
    }

    @Test func nonFallbackLoadHasNoBanner() async {
        let service = RecordingSpotService()
        service.spots = [.sample(id: "1")]
        let vm = MapViewModel(service: service)

        await vm.load()

        #expect(!vm.isFallback)
        #expect(vm.fallbackBannerText == nil)
    }

    // MARK: - Place search → move camera

    @Test func moveCameraCentersOnPlace() {
        let vm = MapViewModel(service: RecordingSpotService())
        vm.moveCamera(to: SpotRegion(latitude: 48.8566, longitude: 2.3522, radiusKm: 10))

        let center = vm.cameraPosition.region?.center
        #expect(center?.latitude == 48.8566)
        #expect(center?.longitude == 2.3522)
    }
}
