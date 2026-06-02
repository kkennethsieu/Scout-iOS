import Foundation
import CoreLocation

/// One node in the create-spot flow's navigation stack. The `share` entry point
/// is the stack root (not a case here); these are the pushed destinations.
nonisolated enum CreateStep: Hashable {
    case confirmLocation                          // map + precise pin (Phase 2)
    case nearbySpots([NearbySpot])                // many candidates near the point
    case sameSpot(NearbySpot)                     // a single likely candidate
    case locationError(LocationErrorSheet.Source) // no GPS / nothing nearby
}

/// Data accumulated as the user moves through the create flow, so steps don't
/// have to thread values through each other.
struct SpotDraft {
    var photoData: Data?
    var metadata: PhotoMetadata?
    var coordinate: CLLocationCoordinate2D?
    var source: LocationErrorSheet.Source = .photoUpload
    var candidates: [NearbySpot] = []
    var chosenSpot: NearbySpot?
}
