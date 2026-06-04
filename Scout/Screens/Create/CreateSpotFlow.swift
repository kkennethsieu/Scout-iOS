import SwiftUI
import CoreLocation

/// Presents the create-spot flow. Apply once (e.g. on `MainTabView`) and toggle
/// `isPresented`.
///
/// The entry sheet (`ShareSpotSheet`) lets the user upload a photo or use their
/// current location; either choice dismisses the sheet and presents the map step
/// to position the spot:
/// - **Photo** → its EXIF coordinate (if any) seeds the pin; missing/invalid
///   GPS falls back to the device location with the fallback banner.
/// - **Current location** → the device location seeds the pin.
///
/// A single flow-owned `CreateReviewViewModel` accumulates the new review as the
/// user advances (map → name picker → form). It's created here on the entry
/// choice and cleared when the flow dismisses, so each attempt starts fresh.
struct CreateSpotFlow: ViewModifier {
    @Binding var isPresented: Bool

    /// Identifiable wrapper so the map cover is *item*-driven — it can never
    /// present without a valid entry (an `isPresented` bool raced with a
    /// separate entry value, which showed a blank cover). The review accumulator
    /// rides along on the item so it's atomic with presentation — reading it from
    /// separate `@State` raced the cover and showed a blank screen.
    private struct MapRoute: Identifiable {
        let id = UUID()
        let entry: CreateMapViewModel.Entry
        var photoData: Data?
        let review: CreateReviewViewModel
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
                        let metadata = PhotoMetadata(data: data)
                        choose(.photo(metadata.coordinate), photoData: data)
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
                CreateFlowContainer(
                    entry: route.entry,
                    photoData: route.photoData,
                    review: route.review,
                    onFinish: { self.route = nil }
                )
            }
    }

    /// Records the choice, creates the review accumulator, and dismisses the
    /// entry sheet; the map opens once the sheet is fully dismissed.
    private func choose(_ entry: CreateMapViewModel.Entry, photoData: Data? = nil) {
        let review = Self.makeReview(entry: entry, photoData: photoData)
        pending = MapRoute(entry: entry, photoData: photoData, review: review)
        isPresented = false
        // TODO: if photo had no GPS *and* location permission is denied, route
        // to LocationErrorSheet instead of the map.
    }

    private func presentMapIfPending() {
        guard let pending else { return }
        route = pending
        self.pending = nil
    }

    /// Seeds the accumulator with the photo and the entry's tentative coordinate;
    /// the target/name and final coordinate are filled by the later steps.
    private static func makeReview(entry: CreateMapViewModel.Entry,
                                   photoData: Data?) -> CreateReviewViewModel {
        let coordinate: CLLocationCoordinate2D?
        switch entry {
        case .photo(let c): coordinate = c
        case .currentLocation(let c): coordinate = c
        }
        return CreateReviewViewModel(target: .newSpot(name: ""),
                                     coordinate: coordinate,
                                     photoData: photoData)
    }
}

// MARK: - Navigation container

/// Hosts the post-entry steps in a single `NavigationStack` so there's one back
/// stack: `CreateMapScreen` is the root and `WriteReviewScreen` is pushed. The
/// Name Picker stays a sheet on the map; picking a name pushes the form.
private struct CreateFlowContainer: View {
    let entry: CreateMapViewModel.Entry
    let photoData: Data?
    let review: CreateReviewViewModel
    var onFinish: () -> Void

    private enum Step: Hashable { case review }
    @State private var path: [Step] = []

    var body: some View {
        NavigationStack(path: $path) {
            CreateMapScreen(entry: entry, photoData: photoData, review: review) {
                path.append(.review)
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .review:
                    WriteReviewScreen(viewModel: review, onComplete: onFinish)
                }
            }
        }
    }
}
