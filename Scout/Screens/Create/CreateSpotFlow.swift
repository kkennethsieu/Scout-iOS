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

    /// Carries the submitted review to the success cover (it has everything the
    /// success screen shows — name, place, photos, spot id).
    private struct SuccessRoute: Identifiable {
        let id = UUID()
        let review: CreateReviewViewModel
    }

    /// Carries the saved spot id to the detail cover.
    private struct DetailRoute: Identifiable {
        let id = UUID()
        let spotID: String
    }

    /// Captured on the user's choice; the map is presented from the entry
    /// sheet's `onDismiss` so the two presentations don't overlap.
    @State private var pending: MapRoute?
    @State private var route: MapRoute?
    /// Each step is dismissed before the next is presented (promoted in the
    /// previous cover's `onDismiss`), so the flow reads as real screen
    /// transitions — slide the form away, then bring the success screen up — not
    /// an in-place swap.
    @State private var pendingSuccess: SuccessRoute?
    @State private var success: SuccessRoute?
    @State private var pendingDetail: DetailRoute?
    @State private var detail: DetailRoute?
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
            .fullScreenCover(item: $route, onDismiss: presentSuccessIfPending) { route in
                CreateFlowContainer(
                    entry: route.entry,
                    photoData: route.photoData,
                    review: route.review,
                    onSucceeded: { succeed(review: route.review) }
                )
            }
            .fullScreenCover(item: $success, onDismiss: presentDetailIfPending) { route in
                SuccessHost(
                    review: route.review,
                    onSeeSpot: { seeSpot(review: route.review) },
                    onDone: { self.success = nil }
                )
            }
            .fullScreenCover(item: $detail) { route in
                NavigationStack {
                    SpotDetailScreen(spotID: route.spotID)
                }
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

    // MARK: - Success / detail hand-offs

    /// The review submitted: dismiss the form cover, then present success once
    /// it's fully gone (via the cover's `onDismiss`).
    private func succeed(review: CreateReviewViewModel) {
        pendingSuccess = SuccessRoute(review: review)
        route = nil
    }

    private func presentSuccessIfPending() {
        guard let pendingSuccess else { return }
        success = pendingSuccess
        self.pendingSuccess = nil
    }

    /// "See your spot": dismiss the success cover, then present the spot detail
    /// once it's gone. With no saved id (shouldn't happen on success) the flow
    /// just closes.
    private func seeSpot(review: CreateReviewViewModel) {
        if let id = review.resultSpotID {
            pendingDetail = DetailRoute(spotID: id)
        }
        success = nil
    }

    private func presentDetailIfPending() {
        guard let pendingDetail else { return }
        detail = pendingDetail
        self.pendingDetail = nil
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

/// Hosts the post-entry steps in a `NavigationStack` so there's one back stack:
/// `CreateMapScreen` is the root and `WriteReviewScreen` is pushed. The Name
/// Picker stays a sheet on the map; picking a name pushes the form. A successful
/// submit (`review.phase == .success`) calls `onSucceeded`, which dismisses this
/// cover and hands off to the success screen.
private struct CreateFlowContainer: View {
    let entry: CreateMapViewModel.Entry
    let photoData: Data?
    let review: CreateReviewViewModel
    /// Fired once the review submits successfully so the flow can dismiss this
    /// cover and present the success screen.
    var onSucceeded: () -> Void

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
                    WriteReviewScreen(viewModel: review)
                }
            }
        }
        .onChange(of: review.phase) { _, phase in
            if phase == .success { onSucceeded() }
        }
    }
}

// MARK: - Success host

/// Hosts `SuccessScreen` and owns its local-only Save toggle (a cover's content
/// closure can't hold `@State`). There's no save endpoint yet — the Saved tab is
/// a placeholder; `review.resultSpotID` is the key for when one lands.
private struct SuccessHost: View {
    let review: CreateReviewViewModel
    var onSeeSpot: () -> Void
    var onDone: () -> Void

    @State private var isSaved = false

    var body: some View {
        SuccessScreen(
            spotName: review.spotName,
            place: review.resultPlace,
            rating: review.draft.rating,
            photos: review.resultPhotos,
            isNewSpot: review.isNewSpot,
            isSaved: isSaved,
            onTapSave: { isSaved.toggle() },
            onSeeSpot: onSeeSpot,
            onDone: onDone
        )
    }
}
