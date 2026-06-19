import Testing
import CoreLocation
@testable import Scout

/// Covers `CreateFlowHost.photoRoute` — the pure decision that sends a picked
/// photo to the map, prompts for location first, or shows the location-error
/// sheet, based on the photo's EXIF coordinate and the current authorization.
struct CreatePhotoRouteTests {

    private let realFix = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)

    // MARK: - Usable GPS always wins, regardless of authorization

    @Test func validGPSGoesToMapEvenWhenDenied() {
        #expect(
            CreateFlowHost.photoRoute(coordinate: realFix, authorization: .denied)
                == .map(realFix)
        )
    }

    @Test func validGPSGoesToMapWhenNotDetermined() {
        #expect(
            CreateFlowHost.photoRoute(coordinate: realFix, authorization: .notDetermined)
                == .map(realFix)
        )
    }

    // MARK: - No usable GPS — depends on authorization

    @Test func noGPSWhenAuthorizedFallsBackToDeviceLocation() {
        #expect(
            CreateFlowHost.photoRoute(coordinate: nil, authorization: .authorizedWhenInUse)
                == .map(nil)
        )
    }

    @Test func nullIslandTreatedAsNoGPS() {
        // (0,0) is rejected by `sanitized`, so it behaves like missing GPS.
        let nullIsland = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        #expect(
            CreateFlowHost.photoRoute(coordinate: nullIsland, authorization: .authorizedWhenInUse)
                == .map(nil)
        )
    }

    @Test func noGPSWhenNotDeterminedRequestsThenMaps() {
        #expect(
            CreateFlowHost.photoRoute(coordinate: nil, authorization: .notDetermined)
                == .requestLocationThenMap
        )
    }

    @Test func noGPSWhenDeniedShowsError() {
        #expect(
            CreateFlowHost.photoRoute(coordinate: nil, authorization: .denied)
                == .locationError
        )
    }

    @Test func noGPSWhenRestrictedShowsError() {
        #expect(
            CreateFlowHost.photoRoute(coordinate: nil, authorization: .restricted)
                == .locationError
        )
    }
}
