import SwiftUI
import MapKit

/// The shared spot-pin layer for any `Map`: drops each spot as a tappable
/// `NearbySpotMarker`, growing the one whose id matches `selectedID`. Reused by
/// the Map tab, the create-flow map, and the saved-list map so every map speaks
/// the same pin language.
///
/// Place it directly inside a `Map { … }` (alongside other content like the user
/// dot). Selection is driven by the `Map`'s `selection:` binding via each pin's tag.
struct SpotPins: MapContent {
    let spots: [SpotSummary]
    var selectedID: String?

    var body: some MapContent {
        ForEach(spots) { spot in
            Annotation(spot.name, coordinate: spot.coordinate) {
                NearbySpotMarker(name: spot.name, isSelected: selectedID == spot.id)
            }
            .tag(spot.id)
            .annotationTitles(.hidden)
        }
    }
}
