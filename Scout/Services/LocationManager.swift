import CoreLocation
import Observation

/// Publishes the user's location for the map (blue dot + recenter button).
///
/// Wraps `CLLocationManager` and surfaces the latest `coordinate` plus the
/// current `authorizationStatus`. Delegate callbacks arrive on the main thread
/// (the manager is created on the main actor) and hop back onto it to mutate
/// observable state.
@Observable
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus

    // CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)   // Los Angeles
    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// `true` once the user has granted some form of location access. The
    /// "when in use" case is spelled differently on macOS, so normalize here.
    var isAuthorized: Bool {
        switch authorizationStatus {
        #if os(macOS)
        case .authorized, .authorizedAlways: return true
        #else
        case .authorizedWhenInUse, .authorizedAlways: return true
        #endif
        default: return false
        }
    }

    /// Begins location updates **only if already authorized** — it never shows the
    /// system permission prompt. Safe to call from `onAppear`; the prompt is gated
    /// behind `requestPermission()` so a primer can explain it first. Idempotent.
    func start() {
        if isAuthorized { manager.startUpdatingLocation() }
    }

    /// Explicitly requests permission (showing the system prompt when status is
    /// `.notDetermined`) and begins updates once granted. Call only from a user
    /// action — the location primer's "Enable", the map recenter button, or the
    /// create flow's "use current location".
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            if isAuthorized { manager.startUpdatingLocation() }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            authorizationStatus = manager.authorizationStatus
            if isAuthorized { manager.startUpdatingLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        MainActor.assumeIsolated {
            coordinate = location.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // Non-fatal: keep the last known coordinate (often a transient sim error).
    }
}
