import SwiftUI
import MapKit

/// A saved list's spots dropped as pins on a map. Pushed from `SavedListDetailScreen`'s
/// floating Map button. Reuses the Map tab's building blocks — `NearbySpotMarker`
/// pins, the `MapSpotPreview` card, and `MapControlButton` — over a fixed set of
/// spots (no backend re-query / "search this area"). Tapping a pin reveals the
/// preview; tapping the preview pushes the shared `SpotDetailScreen`.
struct ListMapScreen: View {
    let title: String
    let spots: [SpotSummary]

    @Environment(\.dismiss) private var dismiss
    /// Optional so previews (which don't inject it) don't crash.
    @Environment(TabBarVisibility.self) private var tabBarVisibility: TabBarVisibility?

    @State private var selectedSpotID: String?
    @State private var cameraPosition: MapCameraPosition

    init(title: String, spots: [SpotSummary]) {
        self.title = title
        self.spots = spots
        let region = MKCoordinateRegion(fitting: spots.map(\.coordinate))
            ?? MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
            )
        _cameraPosition = State(initialValue: .region(region))
    }

    private var selectedSpot: SpotSummary? {
        guard let selectedSpotID else { return nil }
        return spots.first { $0.id == selectedSpotID }
    }

    var body: some View {
        ZStack(alignment: .top) {
            map
            topBar
            fitButton
            SpotPreviewOverlay(spot: selectedSpot)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .onAppear { tabBarVisibility?.requestHidden() }
        .onDisappear { tabBarVisibility?.releaseHidden() }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $cameraPosition, selection: $selectedSpotID) {
            SpotPins(spots: spots, selectedID: selectedSpotID)
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Top bar (back + list name)

    private var topBar: some View {
        HStack(spacing: Spacing.md) {
            MapControlButton(systemImage: "chevron.left") { dismiss() }

            Text(title)
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.md)
                .frame(height: 46)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Re-fit control

    private var fitButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                MapControlButton(systemImage: "scope") {
                    if let region = MKCoordinateRegion(fitting: spots.map(\.coordinate)) {
                        withAnimation(.easeInOut) { cameraPosition = .region(region) }
                    }
                }
            }
        }
        .padding(.trailing, Spacing.lg)
        // Sit above the selected-spot preview card when it's showing.
        .padding(.bottom, selectedSpot == nil ? Spacing.xxxl : 140)
        .animation(.spring(duration: 0.3), value: selectedSpotID)
    }
}

// MARK: - Preview

#Preview("List Map") {
    NavigationStack {
        ListMapScreen(
            title: "Weekend hikes",
            spots: [
                .sample(id: "1", name: "Cedar Cathedral", lat: 45.52, lng: -122.68),
                .sample(id: "2", name: "Mirror Reservoir", lat: 45.40, lng: -122.50),
                .sample(id: "3", name: "Ridge Overlook", lat: 45.60, lng: -122.75)
            ]
        )
    }
}
