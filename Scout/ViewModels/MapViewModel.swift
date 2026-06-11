import SwiftUI
import MapKit
import Observation

nonisolated extension SpotSummary {
    /// The spot's public coordinate, for placing it on a map.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: publicLat, longitude: publicLng)
    }
}

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
    var searchText: String = ""               // visual only until map search is wired
    var selectedSpotID: String?
    var cameraPosition: MapCameraPosition = .automatic

    /// Shown as a "Search this area" button once the user pans/zooms away from
    /// the region the current pins were loaded for.
    private(set) var showSearchArea = false
    /// True while an area re-search is in flight (keeps the existing pins up).
    private(set) var isSearchingArea = false

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

    // MARK: - Dependencies

    private let service: SpotService

    init(service: SpotService = AppServices.spot) {
        self.service = service
    }

    // MARK: - Actions

    func load() async {
        state = .loading
        do {
            spots = try await service.fetchSpots()
            state = .loaded
            frameSpots()
        } catch {
            state = .failed(error.localizedDescription)
        }
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
            spots = try await service.fetchSpots(near: area)
            lastSearchedRegion = area
            // Drop a selection that's no longer on the map.
            if !spots.contains(where: { $0.id == selectedSpotID }) {
                selectedSpotID = nil
            }
        } catch {
            // Keep the existing pins; let the user retry the search.
            showSearchArea = true
        }
    }

    /// Recenters the camera on the user's coordinate (from `LocationManager`).
    func recenter(on coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: span))
    }

    /// Placeholder distance until CoreLocation is wired. Deterministic per spot.
    func distanceText(for spot: SpotSummary) -> String {
        let miles = Double((abs(spot.id.hashValue) % 50) + 1) / 10.0
        return "\(miles.formatted(.number.precision(.fractionLength(1)))) mi"
    }

    /// Frames the camera around all loaded spots, with a little padding.
    private func frameSpots() {
        let lats = spots.map(\.publicLat)
        let lngs = spots.map(\.publicLng)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.05),
            longitudeDelta: max((maxLng - minLng) * 1.4, 0.05)
        )
        let region = MKCoordinateRegion(center: center, span: span)
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
