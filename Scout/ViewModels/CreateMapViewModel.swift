import SwiftUI
import MapKit
import CoreLocation
import Observation

/// Drives the create-flow map: a fixed centre pin (the user pans the map under
/// it), nearby existing spots queried as the pin moves, and a region readout.
/// The pin coordinate is always the visible region's centre.
@Observable
@MainActor
final class CreateMapViewModel {
    /// Top-banner copy, chosen from whether the photo carried a usable location.
    enum Banner: Equatable {
        case standard
        case noPhotoLocation

        var text: String {
            switch self {
            case .standard:
                "Tap a nearby pin to review that spot, or continue with yours."
            case .noPhotoLocation:
                "Couldn't read the location in this photo — drag your pin to where you took it."
            }
        }
    }

    /// How the user arrived at this screen, which decides the starting pin and
    /// the banner.
    enum Entry {
        /// Came from a photo upload, carrying its EXIF coordinate (may be
        /// missing or invalid — we fall back to the device location then).
        case photo(CLLocationCoordinate2D?)
        /// Came from "use my current location". Carries the device coordinate if
        /// it's already known (so the map opens centred on it); `nil` means it
        /// isn't ready yet and we adopt the first fix asynchronously.
        case currentLocation(CLLocationCoordinate2D?)
    }

    // MARK: - Tunables

    /// The nearby-query radius is derived from the visible map area, clamped to
    /// this range so extreme zoom levels don't request absurd windows.
    nonisolated static let minNearbyRadiusMeters: Double = 50
    nonisolated static let maxNearbyRadiusMeters: Double = 5000
    /// Refetch when the pin moves more than this fraction of the current radius…
    nonisolated static let movementFraction: Double = 0.2
    /// …or when the zoom (radius) changes by more than this fraction.
    nonisolated static let zoomFraction: Double = 0.25
    /// Default camera framing on entry.
    nonisolated static let defaultSpanMeters: Double = 600

    // MARK: - State

    private(set) var pinCoordinate: CLLocationCoordinate2D
    var cameraPosition: MapCameraPosition
    private(set) var nearbySpots: [SpotSummary] = []
    var selectedSpotID: String?
    private(set) var regionText: String = "Locating…"
    /// Names of real-world places near the pin (from MapKit, not the spots DB) —
    /// suggestions for naming a brand-new spot in the Name Picker.
    private(set) var nearbyPlaceNames: [String] = []
    var isHybrid = false
    let banner: Banner
    /// True when there's no usable starting coordinate yet, so we should adopt
    /// the device's current location once it's available.
    private(set) var needsCurrentLocation: Bool

    var selectedSpot: SpotSummary? {
        guard let selectedSpotID else { return nil }
        return nearbySpots.first { $0.id == selectedSpotID }
    }

    /// Bottom-CTA title — depends on whether an existing spot is selected.
    var ctaTitle: String { Self.makeCtaTitle(for: selectedSpot) }

    // MARK: - Internals

    private let service: SpotService
    private var lastQueriedCoordinate: CLLocationCoordinate2D?
    private var lastQueriedRadius: Double = 0
    /// Query radius for the currently visible map area (updated on camera idle).
    private var currentRadiusMeters: Double
    private var adoptedCurrentLocation = false
    private var nearbyTask: Task<Void, Never>?
    private var geocodeTask: Task<Void, Never>?
    private var placesTask: Task<Void, Never>?

    // MARK: - Init

    init(entry: Entry, service: SpotService = AppServices.spot) {
        self.service = service

        // Neutral default used until the device's current location arrives.
        let fallback = CLLocationCoordinate2D(latitude: 46.8182, longitude: 8.2275)
        let start: CLLocationCoordinate2D

        switch entry {
        case .photo(let coordinate):
            if let valid = Self.sanitized(coordinate) {
                start = valid
                banner = .standard
                needsCurrentLocation = false
            } else {
                start = fallback
                banner = .noPhotoLocation     // photo had no usable GPS
                needsCurrentLocation = true
            }
        case .currentLocation(let coordinate):
            banner = .standard                // we have a location, just not from a photo
            if let valid = Self.sanitized(coordinate) {
                start = valid
                needsCurrentLocation = false
            } else {
                start = fallback
                needsCurrentLocation = true   // adopt the first GPS fix
            }
        }

        pinCoordinate = start
        let initialRegion = Self.region(around: start)
        cameraPosition = .region(initialRegion)
        currentRadiusMeters = Self.queryRadiusMeters(for: initialRegion)
    }

    // MARK: - Pure logic (unit-tested)

    /// Returns the coordinate only if it's a believable GPS fix — rejects `nil`,
    /// invalid values, and the null-island `(0, 0)` that bad EXIF often yields.
    nonisolated static func sanitized(_ coordinate: CLLocationCoordinate2D?) -> CLLocationCoordinate2D? {
        guard let c = coordinate, CLLocationCoordinate2DIsValid(c) else { return nil }
        guard abs(c.latitude) > 0.0001 || abs(c.longitude) > 0.0001 else { return nil }
        return c
    }

    /// Whether to refetch given a pan + zoom change. The first query
    /// (`fromCoordinate == nil`) always passes. Movement scales with the current
    /// radius; zoom is a relative change in radius.
    nonisolated static func shouldRefetch(fromCoordinate last: CLLocationCoordinate2D?,
                                          fromRadius lastRadius: Double,
                                          toCoordinate current: CLLocationCoordinate2D,
                                          toRadius radius: Double) -> Bool {
        guard let last, lastRadius > 0 else { return true }
        let moved = current.distance(to: last) > radius * movementFraction
        let zoomed = abs(radius - lastRadius) / lastRadius > zoomFraction
        return moved || zoomed
    }

    /// Query radius derived from the visible region (centre→corner), clamped to
    /// `[minNearbyRadiusMeters, maxNearbyRadiusMeters]`.
    nonisolated static func queryRadiusMeters(for region: MKCoordinateRegion) -> Double {
        let center = CLLocation(latitude: region.center.latitude,
                                longitude: region.center.longitude)
        let corner = CLLocation(latitude: region.center.latitude + region.span.latitudeDelta / 2,
                                longitude: region.center.longitude + region.span.longitudeDelta / 2)
        let raw = center.distance(from: corner)
        return min(max(raw, minNearbyRadiusMeters), maxNearbyRadiusMeters)
    }

    nonisolated static func makeCtaTitle(for spot: SpotSummary?) -> String {
        if let spot { "Review \(spot.name)" } else { "Continue with new spot" }
    }

    nonisolated static func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coordinate,
                           latitudinalMeters: defaultSpanMeters,
                           longitudinalMeters: defaultSpanMeters)
    }

    /// Name-Picker suggestions from raw POI names: dedupes (preserving order)
    /// and caps the count.
    nonisolated static func topPlaceNames(_ names: [String], limit: Int = 5) -> [String] {
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }.prefix(limit).map { $0 }
    }

    // MARK: - Lifecycle

    func start() {
        queryNearby(force: true)
        scheduleReverseGeocode()
    }

    /// Fetches nearby real-world place names for the Name Picker. Called only
    /// when the user chooses "continue with a new spot" — not needed when they
    /// tap an existing spot (no Name Picker in that path).
    func loadNearbyPlaces() {
        placesTask?.cancel()
        let target = pinCoordinate
        let radius = currentRadiusMeters
        placesTask = Task { [weak self] in
            await self?.fetchNearbyPlaces(around: target, radiusMeters: radius)
        }
    }

    /// Adopt the device's current location — only for the no-photo-location
    /// fallback, and only once (afterwards the user drives the pin by panning).
    func useCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        guard needsCurrentLocation, !adoptedCurrentLocation,
              let valid = Self.sanitized(coordinate) else { return }
        adoptedCurrentLocation = true
        pinCoordinate = valid
        let region = Self.region(around: valid)
        cameraPosition = .region(region)
        currentRadiusMeters = Self.queryRadiusMeters(for: region)
        queryNearby(force: true)
        scheduleReverseGeocode()
    }

    /// The map settled — with the fixed-centre pin, the region centre is the pin
    /// and the visible span sets the query radius.
    func cameraIdled(at region: MKCoordinateRegion) {
        pinCoordinate = region.center
        currentRadiusMeters = Self.queryRadiusMeters(for: region)
        queryNearby(force: false)
        scheduleReverseGeocode()
    }

    func recenterOnPin() {
        cameraPosition = .region(Self.region(around: pinCoordinate))
    }

    func toggleStyle() {
        isHybrid.toggle()
    }

    // MARK: - Nearby query (debounced + distance-gated)

    private func queryNearby(force: Bool) {
        if !force, !Self.shouldRefetch(fromCoordinate: lastQueriedCoordinate,
                                       fromRadius: lastQueriedRadius,
                                       toCoordinate: pinCoordinate,
                                       toRadius: currentRadiusMeters) {
            return
        }
        nearbyTask?.cancel()
        let target = pinCoordinate
        let radius = currentRadiusMeters
        nearbyTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))   // debounce
            guard let self, !Task.isCancelled else { return }
            await self.performNearbyQuery(target, radiusMeters: radius)
        }
    }

    private func performNearbyQuery(_ coordinate: CLLocationCoordinate2D, radiusMeters: Double) async {
        let region = SpotRegion(latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                radiusKm: radiusMeters / 1000)
        do {
            let spots = try await service.fetchSpots(near: region)
            guard !Task.isCancelled else { return }
            nearbySpots = spots
            lastQueriedCoordinate = coordinate
            lastQueriedRadius = radiusMeters
            // Drop a selection that's no longer present.
            if !spots.contains(where: { $0.id == selectedSpotID }) {
                selectedSpotID = nil
            }
        } catch {
            // Keep the existing pins; the user can keep adjusting.
        }
    }

    // MARK: - Reverse geocoding

    private func scheduleReverseGeocode() {
        geocodeTask?.cancel()
        let target = pinCoordinate
        geocodeTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.reverseGeocode(target)
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        // Fresh geocoder per call avoids the "already geocoding" error.
        let placemark: CLPlacemark? = await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                continuation.resume(returning: placemarks?.first)
            }
        }
        guard !Task.isCancelled, let place = placemark else { return }
        let locality = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea
        let text = [locality, place.country].compactMap { $0 }.joined(separator: ", ")
        if !text.isEmpty {
            regionText = text
        }
    }

    // MARK: - Nearby places (Name Picker)

    private func fetchNearbyPlaces(around coordinate: CLLocationCoordinate2D,
                                   radiusMeters: Double) async {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: radiusMeters)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: Self.photoWorthyCategories)

        let response = try? await MKLocalSearch(request: request).start()
        guard !Task.isCancelled, let response else { return }

        nearbyPlaceNames = Self.topPlaceNames(response.mapItems.compactMap(\.name))
    }
    
    private static let photoWorthyCategories: [MKPointOfInterestCategory] = {
        var c: [MKPointOfInterestCategory] = [
            .park, .nationalPark, .beach, .campground,
            .museum, .zoo, .aquarium, .amusementPark, .marina,
            
        ]
        if #available(iOS 18.0, *) {
            c += [.landmark, .nationalMonument, .castle, .fortress]
        }
        return c
    }()
    
}

// MARK: - Distance helper

private extension CLLocationCoordinate2D {
    nonisolated func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
