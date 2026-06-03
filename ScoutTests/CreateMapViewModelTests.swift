import Testing
import CoreLocation
import MapKit
@testable import Scout

/// Covers `CreateMapViewModel`'s pure decision logic: EXIF coordinate
/// sanitising, the distance-gated refetch, CTA-title derivation, and the
/// banner chosen at init.
@MainActor
struct CreateMapViewModelTests {

    // MARK: - EXIF sanitising

    @Test func sanitizedRejectsNilAndNullIsland() {
        #expect(CreateMapViewModel.sanitized(nil) == nil)
        #expect(CreateMapViewModel.sanitized(CLLocationCoordinate2D(latitude: 0, longitude: 0)) == nil)
    }

    @Test func sanitizedRejectsOutOfRange() {
        #expect(CreateMapViewModel.sanitized(CLLocationCoordinate2D(latitude: 200, longitude: 0)) == nil)
    }

    @Test func sanitizedAcceptsRealFix() {
        let real = CLLocationCoordinate2D(latitude: 46.5572, longitude: 8.5614)
        #expect(CreateMapViewModel.sanitized(real) != nil)
    }

    // MARK: - Refetch gate (pan scaled by zoom + zoom change)

    @Test func refetchAlwaysOnFirstQuery() {
        let point = CLLocationCoordinate2D(latitude: 46.55, longitude: 8.56)
        #expect(CreateMapViewModel.shouldRefetch(fromCoordinate: nil, fromRadius: 0,
                                                 toCoordinate: point, toRadius: 500) == true)
    }

    @Test func refetchSkipsSmallPanForRadius() {
        let last = CLLocationCoordinate2D(latitude: 46.55000, longitude: 8.56000)
        // ~1.5 m away — far under 20% of a 500 m radius (100 m) and no zoom change.
        let near = CLLocationCoordinate2D(latitude: 46.550012, longitude: 8.560005)
        #expect(CreateMapViewModel.shouldRefetch(fromCoordinate: last, fromRadius: 500,
                                                 toCoordinate: near, toRadius: 500) == false)
    }

    @Test func refetchOnPanScaledToRadius() {
        let last = CLLocationCoordinate2D(latitude: 46.5500, longitude: 8.5600)
        // ~111 m away — beyond 20% of a 200 m radius (40 m).
        let far = CLLocationCoordinate2D(latitude: 46.5510, longitude: 8.5600)
        #expect(CreateMapViewModel.shouldRefetch(fromCoordinate: last, fromRadius: 200,
                                                 toCoordinate: far, toRadius: 200) == true)
        // …but the same 111 m pan is within 20% of a 1 km radius (200 m).
        #expect(CreateMapViewModel.shouldRefetch(fromCoordinate: last, fromRadius: 1000,
                                                 toCoordinate: far, toRadius: 1000) == false)
    }

    @Test func refetchOnZoomChange() {
        let here = CLLocationCoordinate2D(latitude: 46.55, longitude: 8.56)
        // Same point, radius 200 → 500 m (150% change > 25%).
        #expect(CreateMapViewModel.shouldRefetch(fromCoordinate: here, fromRadius: 200,
                                                 toCoordinate: here, toRadius: 500) == true)
        // Same point, radius 200 → 210 m (5% change < 25%).
        #expect(CreateMapViewModel.shouldRefetch(fromCoordinate: here, fromRadius: 200,
                                                 toCoordinate: here, toRadius: 210) == false)
    }

    // MARK: - Radius derivation + clamping

    @Test func queryRadiusClampsTinyRegionToMin() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.55, longitude: 8.56),
            span: MKCoordinateSpan(latitudeDelta: 0.00001, longitudeDelta: 0.00001)
        )
        #expect(CreateMapViewModel.queryRadiusMeters(for: region) == CreateMapViewModel.minNearbyRadiusMeters)
    }

    @Test func queryRadiusClampsHugeRegionToMax() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.55, longitude: 8.56),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
        #expect(CreateMapViewModel.queryRadiusMeters(for: region) == CreateMapViewModel.maxNearbyRadiusMeters)
    }

    // MARK: - Name Picker place suggestions

    @Test func topPlaceNamesDedupesPreservingOrder() {
        let names = ["Muir Woods", "Bixby Creek Bridge", "Muir Woods", "Pfeiffer Beach"]
        #expect(CreateMapViewModel.topPlaceNames(names) ==
                ["Muir Woods", "Bixby Creek Bridge", "Pfeiffer Beach"])
    }

    @Test func topPlaceNamesCapsAtLimit() {
        let names = (1...10).map { "Place \($0)" }
        #expect(CreateMapViewModel.topPlaceNames(names).count == 5)
        #expect(CreateMapViewModel.topPlaceNames(names, limit: 3) == ["Place 1", "Place 2", "Place 3"])
    }

    @Test func topPlaceNamesEmptyStaysEmpty() {
        #expect(CreateMapViewModel.topPlaceNames([]).isEmpty)
    }

    // MARK: - Radius scaling

    @Test func queryRadiusScalesBetweenClamps() {
        let small = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.55, longitude: 8.56),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        let large = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.55, longitude: 8.56),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        #expect(CreateMapViewModel.queryRadiusMeters(for: large) > CreateMapViewModel.queryRadiusMeters(for: small))
    }

    // MARK: - CTA title

    @Test func ctaTitleForNewSpot() {
        #expect(CreateMapViewModel.makeCtaTitle(for: nil) == "Continue with new spot")
    }

    @Test func ctaTitleForExistingSpot() {
        let spot = SpotSummary.sample(name: "Cedar Cathedral")
        #expect(CreateMapViewModel.makeCtaTitle(for: spot) == "Review Cedar Cathedral")
    }

    // MARK: - Banner selection at init

    @Test func bannerFallsBackWhenPhotoHasNoLocation() {
        let vm = CreateMapViewModel(entry: .photo(nil), service: MockSpotService())
        #expect(vm.banner == .noPhotoLocation)
        #expect(vm.needsCurrentLocation)
    }

    @Test func bannerFallsBackOnNullIsland() {
        let vm = CreateMapViewModel(
            entry: .photo(CLLocationCoordinate2D(latitude: 0, longitude: 0)),
            service: MockSpotService()
        )
        #expect(vm.banner == .noPhotoLocation)
    }

    @Test func bannerStandardWithPhotoLocation() {
        let vm = CreateMapViewModel(
            entry: .photo(CLLocationCoordinate2D(latitude: 46.5572, longitude: 8.5614)),
            service: MockSpotService()
        )
        #expect(vm.banner == .standard)
        #expect(vm.needsCurrentLocation == false)
    }

    @Test func currentLocationEntryWithoutCoordinateAdoptsLater() {
        let vm = CreateMapViewModel(entry: .currentLocation(nil), service: MockSpotService())
        #expect(vm.banner == .standard)
        #expect(vm.needsCurrentLocation)
    }

    @Test func currentLocationEntrySeededCentersImmediately() {
        let here = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        let vm = CreateMapViewModel(entry: .currentLocation(here), service: MockSpotService())
        #expect(vm.banner == .standard)
        #expect(vm.needsCurrentLocation == false)
        #expect(vm.pinCoordinate.latitude == here.latitude)
    }
}
