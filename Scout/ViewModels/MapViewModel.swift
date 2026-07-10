import SwiftUI
import MapKit
import Observation

// `SpotSummary.coordinate` lives in Extensions/SpotSummary+Location.swift.

@Observable
@MainActor
final class MapViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    private(set) var spots: [SpotSummary] = []
    private(set) var state: LoadState = .idle
    var selectedSpotID: String?
    var cameraPosition: MapCameraPosition = .automatic
    /// The user's location (set by the screen), for real preview-card distances.
    var userCoordinate: CLLocationCoordinate2D?

    /// Shown as a "Search this area" button once the user pans/zooms away from
    /// the region the current pins were loaded for.
    private(set) var showSearchArea = false
    /// True while an area re-search is in flight (keeps the existing pins up).
    private(set) var isSearchingArea = false
    /// The backend had no spots near the query area and returned popular spots
    /// from a default region instead. Drives the fallback banner + pin framing.
    private(set) var isFallback = false

    /// The area currently visible on the map (updated as the camera settles).
    private var visibleRegion: SpotRegion?
    /// The area the on-screen pins were loaded for.
    private var lastSearchedRegion: SpotRegion?
    /// Debounce handle so rapid taps coalesce into one request.
    private var searchTask: Task<Void, Never>?

    var selectedSpot: SpotSummary? {
        guard let selectedSpotID else { return nil }
        return spots.first { $0.id == selectedSpotID }
    }

    /// Re-center on the user only once, when their first fix arrives.
    private var hasCenteredOnUser = false

    // MARK: - Dependencies

    private let service: SpotService
    private let defaultRadiusKm: Double = 50
    /// Pins per fetch. The map doesn't paginate; this matches the single-page
    /// count the old `.items` convenience returned.
    private let pageSize = 20

    init(service: SpotService = AppServices.spot) {
        self.service = service
    }

    /// Where to query: around the user when known, else `nil` (the service falls
    /// back to its default LA window).
    private var queryRegion: SpotRegion? {
        userCoordinate.map {
            SpotRegion(latitude: $0.latitude, longitude: $0.longitude, radiusKm: defaultRadiusKm)
        }
    }

    // MARK: - Actions

    /// Banner copy shown when the map is showing fallback (default-region) spots
    /// because nothing was found near the user; `nil` when not in fallback mode.
    /// The city is read from the returned spots (the backend sends no separate
    /// fallback-city field).
    var fallbackBannerText: String? {
        guard isFallback else { return nil }
        if let city = spots.first?.city, !city.isEmpty {
            return "No spots near you — here are popular spots in \(city)."
        }
        return "No spots near you — here are some popular spots instead."
    }

    func load() async {
        state = .loading
        do {
            let page = try await service.fetchSpots(near: queryRegion, limit: pageSize, cursor: nil)
            spots = page.items
            isFallback = page.isFallback
            state = .loaded
            // In fallback mode the pins are in a default region (not near the
            // user), so frame them to keep them on-screen rather than centering
            // on the user's empty area.
            if let userCoordinate, !isFallback {
                centerOnUser(userCoordinate)
            } else {
                frameSpots()
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Adopts the user's latest coordinate. On the first fix, re-fetches spots near
    /// them and centers the camera on them; later fixes only refresh `userCoordinate`
    /// (for distance labels), no reload.
    func applyUserLocation(_ coordinate: CLLocationCoordinate2D?) async {
        userCoordinate = coordinate
        guard coordinate != nil, !hasCenteredOnUser else { return }
        hasCenteredOnUser = true
        await load()
    }

    /// Called when the map camera settles. Reveals the "Search this area"
    /// button once the camera has moved meaningfully from the loaded region.
    func cameraMoved(to region: MKCoordinateRegion) {
        let area = region.spotRegion
        visibleRegion = area

        guard let last = lastSearchedRegion else {
            // No baseline yet (pre-first-load); don't prompt.
            return
        }
        let movedFar = area.distanceKm(to: last) > last.radiusKm * 0.35
        let zoomChanged = abs(area.radiusKm - last.radiusKm) / last.radiusKm > 0.5
        showSearchArea = movedFar || zoomChanged
    }

    /// Re-queries the backend for the currently visible area, debounced so we
    /// don't fire on every settle. Keeps the current pins until results arrive.
    func searchVisibleArea() {
        guard let area = visibleRegion else { return }
        showSearchArea = false

        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))   // debounce
            guard let self, !Task.isCancelled else { return }
            await self.performAreaSearch(area)
        }
    }
    
    func dismissError() {
        state = .loaded
    }

    private func performAreaSearch(_ area: SpotRegion) async {
        isSearchingArea = true
        defer { isSearchingArea = false }
        do {
            let page = try await service.fetchSpots(near: area, limit: pageSize, cursor: nil)
            spots = page.items
            isFallback = page.isFallback
            lastSearchedRegion = area
            // Fallback pins aren't in the searched area, so frame them to keep
            // them visible; a normal search leaves the user's camera untouched.
            if isFallback { frameSpots() }
            // Drop a selection that's no longer on the map.
            if !spots.contains(where: { $0.id == selectedSpotID }) {
                selectedSpotID = nil
            }
        } catch {
            // Keep the existing pins; let the user retry the search.
            showSearchArea = true
        }
    }

    /// Jump the camera to a searched place. The camera-idle handler
    /// (`cameraMoved(to:)`) then reveals "Search this area" so the user can load
    /// spots for the new region.
    func moveCamera(to region: SpotRegion) {
        cameraPosition = .region(MKCoordinateRegion(region))
    }

    /// Recenters the camera on the user's coordinate (from `LocationManager`).
    func recenter(on coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: span))
    }

    /// Centers the camera on the user and adopts that area as the "Search this area"
    /// baseline, so panning away from the user's region reveals the button.
    private func centerOnUser(_ coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        cameraPosition = .region(region)
        let area = region.spotRegion
        lastSearchedRegion = area
        visibleRegion = area
        showSearchArea = false
    }

    /// Real distance from the user to `spot`, or `nil` when there's no location.
    func distanceText(for spot: SpotSummary) -> String? {
        spot.distanceText(from: userCoordinate)
    }

    /// Frames the camera around all loaded spots, with a little padding.
    private func frameSpots() {
        guard let region = MKCoordinateRegion(fitting: spots.map(\.coordinate)) else { return }
        cameraPosition = .region(region)

        // Baseline for the "Search this area" prompt: the pins cover this area.
        let area = region.spotRegion
        lastSearchedRegion = area
        visibleRegion = area
        showSearchArea = false
    }
}

// MARK: - Region conversion
// `MKCoordinateRegion.spotRegion` lives in Extensions/MKCoordinateRegion+SpotRegion.swift.

private extension SpotRegion {
    func distanceKm(to other: SpotRegion) -> Double {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b) / 1000
    }
}
