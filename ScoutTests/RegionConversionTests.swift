import Testing
import MapKit
@testable import Scout

/// `MKCoordinateRegion.spotRegion` — the center+corner-radius converter that turns
/// a MapKit region (from a resolved place or the visible map) into the
/// `SpotRegion` query window. Pure math, no network.
struct RegionConversionTests {

    @Test func carriesCenterAndProducesPositiveRadius() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8651, longitude: -119.5383), // Yosemite
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        let spot = region.spotRegion

        #expect(spot.latitude == 37.8651)
        #expect(spot.longitude == -119.5383)
        #expect(spot.radiusKm > 0)
        // Half a degree of latitude is ~55 km; the corner radius is a bit more.
        #expect(spot.radiusKm > 30 && spot.radiusKm < 90)
    }

    @Test func largerSpanYieldsLargerRadius() {
        let center = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        let tight = MKCoordinateRegion(center: center,
                                       span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        let wide = MKCoordinateRegion(center: center,
                                      span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))

        #expect(wide.spotRegion.radiusKm > tight.spotRegion.radiusKm)
    }
}
