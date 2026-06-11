import MapKit

extension MKCoordinateRegion {
    /// Approximates this region as a center + radius (km to the visible corner) —
    /// the `SpotRegion` query window used by `SpotService.fetchSpots(near:)`.
    var spotRegion: SpotRegion {
        let centerLocation = CLLocation(latitude: center.latitude,
                                        longitude: center.longitude)
        let corner = CLLocation(latitude: center.latitude + span.latitudeDelta / 2,
                                longitude: center.longitude + span.longitudeDelta / 2)
        return SpotRegion(latitude: center.latitude,
                          longitude: center.longitude,
                          radiusKm: centerLocation.distance(from: corner) / 1000)
    }
}
