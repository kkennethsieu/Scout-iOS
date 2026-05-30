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
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
