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

    /// Builds a region centred on a `SpotRegion` (the inverse of `spotRegion`) —
    /// used to move a map camera to a resolved place. `radiusKm` is the centre→
    /// corner distance, so the visible window spans roughly a diameter across.
    init(_ region: SpotRegion) {
        self.init(center: CLLocationCoordinate2D(latitude: region.latitude,
                                                 longitude: region.longitude),
                  latitudinalMeters: region.radiusKm * 2000,   // radius→diameter, km→m
                  longitudinalMeters: region.radiusKm * 2000)
    }

    /// A region that frames all `coordinates` with a little padding, clamped to a
    /// minimum span so a single (or tightly-clustered) spot isn't zoomed in absurdly.
    /// `nil` when `coordinates` is empty. Reused wherever a set of spots is fitted
    /// on screen (Map tab, saved-list map).
    init?(fitting coordinates: [CLLocationCoordinate2D],
          paddingFactor: Double = 1.4,
          minimumSpan: Double = 0.05) {
        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else { return nil }

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLng + maxLng) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * paddingFactor, minimumSpan),
            longitudeDelta: max((maxLng - minLng) * paddingFactor, minimumSpan)
        )
        self.init(center: center, span: span)
    }
}
