import SwiftUI

/// Presents the create-spot flow. Apply once (e.g. on `MainTabView`) and toggle
/// `isPresented`.
///
/// The entry sheet (`ShareSpotSheet`) lets the user upload a photo or use their
/// current location; either choice dismisses the sheet and presents
/// `CreateMapScreen` to position the spot:
/// - **Photo** → its EXIF coordinate (if any) seeds the pin; missing/invalid
///   GPS falls back to the device location with the fallback banner.
/// - **Current location** → the device location seeds the pin.
struct CreateSpotFlow: ViewModifier {
    @Binding var isPresented: Bool

    /// Identifiable wrapper so the map cover is *item*-driven — it can never
    /// present without a valid entry (an `isPresented` bool raced with a
    /// separate entry value, which showed a blank cover).
    private struct MapRoute: Identifiable {
        let id = UUID()
        let entry: CreateMapViewModel.Entry
    }

    /// Captured on the user's choice; the map is presented from the entry
    /// sheet's `onDismiss` so the two presentations don't overlap.
    @State private var pending: MapRoute?
    @State private var route: MapRoute?
    /// Warmed up while the entry sheet is open so the current location is ready
    /// the moment the user taps "use my current location".
    @State private var location = LocationManager()

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: presentMapIfPending) {
                ShareSpotSheet(
                    onPhotoPicked: { data in
                        // TODO: thread a thumbnail through to CreateMapScreen.
                        let metadata = PhotoMetadata(data: data)
                        choose(.photo(metadata.coordinate))
                    },
                    onUseCurrentLocation: {
                        // Centre the map on the current location (synchronous in
                        // DEBUG via the dev override; otherwise adopted async).
                        location.start()
                        choose(.currentLocation(location.coordinate))
                    }
                )
                .onAppear { location.start() }
            }
            .fullScreenCover(item: $route) { route in
                CreateMapScreen(entry: route.entry)
            }
    }

    /// Records the choice and dismisses the entry sheet; the map opens once the
    /// sheet is fully dismissed (see `presentMapIfPending`).
    private func choose(_ entry: CreateMapViewModel.Entry) {
        pending = MapRoute(entry: entry)
        isPresented = false
        // TODO: if photo had no GPS *and* location permission is denied, route
        // to LocationErrorSheet instead of the map.
    }

    private func presentMapIfPending() {
        guard let pending else { return }
        route = pending
        self.pending = nil
    }
}
