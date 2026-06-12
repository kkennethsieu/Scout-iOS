import Testing
import Foundation
import CoreLocation
@testable import Scout

/// Reference-type stub that records the `near:` region of each spots fetch and how
/// many fetches ran, so we can assert the Map queries around the user and reloads
/// only on the first fix.
private final class RecordingSpotService: SpotService, @unchecked Sendable {
    var spots: [SpotSummary] = []
    private(set) var lastRegion: SpotRegion?
    private(set) var fetchCount = 0

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        lastRegion = region
        fetchCount += 1
        return PaginatedSpots(items: spots, limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String) async throws -> [Review] { [] }
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
}
