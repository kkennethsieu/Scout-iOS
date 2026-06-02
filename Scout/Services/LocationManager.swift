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

    private let manager = CLLocationManager()

    // MARK: - Development override
    //
    // TEMP: while developing we pin the "user" to a fixed coordinate so the dot
    // and recenter button work without real GPS (and without a permission
    // prompt). Set to `nil` — or delete this whole block — to use real GPS.
    #if DEBUG
    private let fixedLocation: CLLocationCoordinate2D? =
        CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)   // Los Angeles
    #else
    private let fixedLocation: CLLocationCoordinate2D? = nil
    #endif

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

    /// The "granted" status to publish for the dev override, per platform.
    private static var grantedStatus: CLAuthorizationStatus {
        #if os(macOS)
        .authorizedAlways
        #else
        .authorizedWhenInUse
        #endif
    }

    /// Requests permission (if needed) and begins updates. Idempotent.
    func start() {
        if let fixedLocation {
            authorizationStatus = Self.grantedStatus
            coordinate = fixedLocation
            return
        }
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
            guard fixedLocation == nil else { return }
            if isAuthorized { manager.startUpdatingLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        MainActor.assumeIsolated {
            guard fixedLocation == nil else { return }
            coordinate = location.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // Non-fatal: keep the last known coordinate (often a transient sim error).
    }
}
