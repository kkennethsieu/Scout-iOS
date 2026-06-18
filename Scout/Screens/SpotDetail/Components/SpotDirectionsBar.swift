import SwiftUI

/// Floating bar pinned to the bottom of Spot Detail. A single "Directions"
/// action that opens Apple Maps with a driving route to the spot's public
/// coordinates. Sits on a background fade so the scroll content dissolves behind
/// it and it reads as floating rather than a hard toolbar.
struct SpotDirectionsBar: View {
    let latitude: Double
    let longitude: Double
    let name: String

    @Environment(\.openURL) private var openURL

    var body: some View {
        SPrimaryButton(title: "Directions", icon: "arrow.triangle.turn.up.right.diamond.fill") {
            openURL(directionsURL)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xs)
        .background(
            LinearGradient(
                colors: [Color.sBackground.opacity(0), Color.sBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    /// An Apple Maps *directions* link (drive) to the spot's public location.
    private var directionsURL: URL {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "dirflg", value: "d")
        ]
        return components.url ?? URL(string: "https://maps.apple.com/")!
    }
}
