import SwiftUI
import MapKit
import CoreLocation
import Observation

/// Drives the Confirm Location picker. The pin is fixed to the screen's centre,
/// so the *centre of the visible map region* is the selected coordinate — moving
/// the map adjusts the pin. On each camera-idle we reverse-geocode that centre
/// (debounced) to fill the "Spotted in …" readout.
@Observable
@MainActor
final class ConfirmLocationViewModel {
    var cameraPosition: MapCameraPosition
    var searchText: String = ""
    var isHybrid = false

    private(set) var coordinate: CLLocationCoordinate2D
    private(set) var regionText: String = "Locating…"

    private var geocodeTask: Task<Void, Never>?

    init(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 46.5572, longitude: 8.5614)) {
        self.coordinate = coordinate
        cameraPosition = .region(
            MKCoordinateRegion(center: coordinate,
                               span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        )
    }

    var mapStyle: MapStyle {
        isHybrid ? .hybrid(elevation: .realistic) : .standard(pointsOfInterest: .excludingAll)
    }

    func toggleStyle() {
        isHybrid.toggle()
    }

    /// Called when the map camera settles. Updates the selected coordinate to the
    /// region centre and schedules a reverse-geocode.
    func cameraIdled(at region: MKCoordinateRegion) {
        coordinate = region.center
        scheduleReverseGeocode()
    }

    func recenter(on coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(
                MKCoordinateRegion(center: coordinate,
                                   span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            )
        }
    }

    /// Resolves the initial readout.
    func start() {
        scheduleReverseGeocode()
    }

    // MARK: - Reverse geocoding

    private func scheduleReverseGeocode() {
        geocodeTask?.cancel()
        let target = coordinate
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
}
