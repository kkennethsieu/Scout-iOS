import CoreLocation

nonisolated extension SpotSummary {
    /// The spot's public coordinate, for placing it on a map.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: publicLat, longitude: publicLng)
    }

    /// Distance in miles from `origin` to this spot, or `nil` when there's no
    /// origin (location denied / not yet granted).
    func distanceMiles(from origin: CLLocationCoordinate2D?) -> Double? {
        guard let origin else { return nil }
        let meters = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: publicLat, longitude: publicLng))
        return meters / 1609.344
    }

    /// Formatted distance (e.g. "4.2 mi"), or `nil` when there's no origin.
    func distanceText(from origin: CLLocationCoordinate2D?) -> String? {
        guard let miles = distanceMiles(from: origin) else { return nil }
        return "\(miles.formatted(.number.precision(.fractionLength(1)))) mi"
    }
}
