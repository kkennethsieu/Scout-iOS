import Testing
import Foundation
import CoreLocation
@testable import Scout

/// Stub returning a fixed spot list regardless of region, so we can drive the
/// create flow's branching deterministically.
private struct StubSpotService: SpotService {
    var spots: [SpotSummary] = []
    var error: Error?

    func fetchSpots(near region: SpotRegion?) async throws -> [SpotSummary] {
        if let error { throw error }
        return spots
    }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String) async throws -> [Review] { [] }
}

private struct StubError: LocalizedError {
    var errorDescription: String? { "stub failure" }
}

private let testCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

@MainActor
struct CreateSpotViewModelTests {

    // MARK: - Photo path

    @Test func photoWithoutGPSRoutesToLocationError() async {
        let vm = CreateSpotViewModel(service: StubSpotService(spots: SpotSummary.samples))

        // Non-image bytes → no EXIF → no coordinate.
        await vm.pickedPhoto(Data([0x00, 0x01, 0x02, 0x03]))

        #expect(vm.path == [.locationError(.photoUpload)])
    }

    // MARK: - Lookup branching (via confirmedLocation, which takes a coordinate)

    @Test func multipleNearbySpotsRouteToNearbySheet() async {
        let vm = CreateSpotViewModel(service: StubSpotService(spots: SpotSummary.samples))

        await vm.confirmedLocation(testCoordinate)

        guard case let .nearbySpots(spots) = vm.path.last else {
            Issue.record("Expected .nearbySpots, got \(String(describing: vm.path.last))")
            return
        }
        #expect(spots.count == SpotSummary.samples.count)
        // Sorted nearest-first.
        #expect(spots == spots.sorted { $0.distanceMeters < $1.distanceMeters })
    }

    @Test func singleNearbySpotRoutesToSameSpotSheet() async {
        let one = [SpotSummary.sample(id: "solo", name: "Solo Ridge")]
        let vm = CreateSpotViewModel(service: StubSpotService(spots: one))

        await vm.confirmedLocation(testCoordinate)

        guard case let .sameSpot(spot) = vm.path.last else {
            Issue.record("Expected .sameSpot, got \(String(describing: vm.path.last))")
            return
        }
        #expect(spot.name == "Solo Ridge")
    }

    @Test func noNearbySpotsRoutesToLocationError() async {
        let vm = CreateSpotViewModel(service: StubSpotService(spots: []))

        await vm.confirmedLocation(testCoordinate)

        #expect(vm.path.last == .locationError(.currentLocation))
    }

    @Test func lookupFailureRoutesToLocationError() async {
        let vm = CreateSpotViewModel(service: StubSpotService(error: StubError()))

        await vm.confirmedLocation(testCoordinate)

        #expect(vm.path.last == .locationError(.currentLocation))
    }

    // MARK: - Mapping

    @Test func mapsSummaryCategoryToCity() async {
        let vm = CreateSpotViewModel(service: StubSpotService(spots: SpotSummary.samples))

        await vm.confirmedLocation(testCoordinate)

        guard case let .nearbySpots(spots) = vm.path.last else {
            Issue.record("Expected .nearbySpots")
            return
        }
        // Sample spots are all in Portland.
        #expect(spots.allSatisfy { $0.category == "Portland" })
    }

    // MARK: - Current location

    @Test func currentLocationWithCoordinateRoutesToConfirm() {
        let vm = CreateSpotViewModel(service: StubSpotService())

        vm.choseCurrentLocation(coordinate: testCoordinate)

        #expect(vm.path == [.confirmLocation])
    }

    @Test func currentLocationWithoutCoordinateRoutesToError() {
        let vm = CreateSpotViewModel(service: StubSpotService())

        vm.choseCurrentLocation(coordinate: nil)

        #expect(vm.path == [.locationError(.currentLocation)])
    }

    // MARK: - Terminal intents & reset

    @Test func selectingASpotRequestsClose() async {
        let vm = CreateSpotViewModel(service: StubSpotService(spots: SpotSummary.samples))
        await vm.confirmedLocation(testCoordinate)

        vm.selectedNearby(NearbySpot.samples[0])

        #expect(vm.requestClose)
    }

    @Test func differentSpotPopsToRoot() async {
        let one = [SpotSummary.sample(id: "solo")]
        let vm = CreateSpotViewModel(service: StubSpotService(spots: one))
        await vm.confirmedLocation(testCoordinate)
        #expect(!vm.path.isEmpty)

        vm.differentSpot()

        #expect(vm.path.isEmpty)
    }

    @Test func resetClearsState() async {
        let vm = CreateSpotViewModel(service: StubSpotService(spots: SpotSummary.samples))
        await vm.confirmedLocation(testCoordinate)
        vm.selectedNearby(NearbySpot.samples[0])

        vm.reset()

        #expect(vm.path.isEmpty)
        #expect(!vm.requestClose)
        #expect(vm.detent == CreateSpotViewModel.shareDetent)
    }
}
