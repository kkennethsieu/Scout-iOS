import SwiftUI
import MapKit

/// "Look Around" — fetches the Look Around scene for the spot's public location
/// and renders it as a titled section. Renders nothing while loading or when the
/// location has no Look Around coverage, matching the other detail sections that
/// self-hide when they have no data.
struct SpotLookAround: View {
    let latitude: Double
    let longitude: Double

    @State private var scene: MKLookAroundScene?
    @State private var isLoading = true

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var body: some View {
        Group {
            if isLoading {
                SSection(title: "Look Around") {
                    SkeletonBox(height: 200, cornerRadius: Radius.lg)
                        .shimmering()
                }
            } else if let scene {
                SSection(title: "Look Around") {
                    LookAroundExplorer(scene: scene)
                }
            }
            // No coverage → render nothing, like the other detail sections.
        }
        .task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            scene = try? await request.scene
            isLoading = false
        }
    }
}
