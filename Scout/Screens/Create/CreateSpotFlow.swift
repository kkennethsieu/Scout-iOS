import SwiftUI
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

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

    /// The "can't determine location" sheet (no usable photo GPS + denied
    /// location). Carries the photo data so a future "retry this photo" can reuse
    /// it; "pick a different photo" just reopens the entry sheet.
    private struct ErrorRoute: Identifiable {
        let id = UUID()
        var photoData: Data?
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
    /// The location-error sheet, presented after the entry sheet dismisses (two
    /// sheets can't overlap), mirroring the map hand-off.
    @State private var pendingError: ErrorRoute?
    @State private var errorRoute: ErrorRoute?
    /// "Pick a different photo" tapped — reopen the entry sheet once the error
    /// sheet has dismissed.
    @State private var pendingReopen = false
    /// Warmed up while the entry sheet is open so the current location is ready
    /// the moment the user taps "use my current location".
    @State private var location = LocationManager()

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: onEntryDismissed) {
                ShareSpotSheet(
                    onPhotoPicked: { data in
                        let coordinate = PhotoMetadata(data: data).coordinate
                        switch Self.photoRoute(coordinate: coordinate,
                                               authorization: location.authorizationStatus) {
                        case .map(let seed):
                            choose(.photo(seed), photoData: data)
                        case .requestLocationThenMap:
                            // Permission not asked yet — prompt, then let the map
                            // adopt the device location as its fallback.
                            location.requestPermission()
                            choose(.photo(nil), photoData: data)
                        case .locationError:
                            presentError(photoData: data)
                        }
                    },
                    onUseCurrentLocation: {
                        // Centre the map on the current location (synchronous in
                        // DEBUG via the dev override; otherwise adopted async). The
                        // user explicitly chose location, so prompt if needed.
                        location.requestPermission()
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
            .sheet(item: $errorRoute, onDismiss: onErrorDismissed) { _ in
                LocationErrorSheet(
                    onPickDifferentPhoto: {
                        // Reopen the entry sheet (its photo picker) once this
                        // sheet dismisses.
                        pendingReopen = true
                        errorRoute = nil
                    },
                    onEnableLocation: {
                        openLocationSettings()
                        errorRoute = nil
                    }
                )
            }
    }

    /// Records the choice, creates the review accumulator, and dismisses the
    /// entry sheet; the map opens once the sheet is fully dismissed.
    private func choose(_ entry: CreateMapViewModel.Entry, photoData: Data? = nil) {
        let review = Self.makeReview(entry: entry, photoData: photoData)
        pending = MapRoute(entry: entry, photoData: photoData, review: review)
        isPresented = false
    }

    /// Records the location-error case and dismisses the entry sheet; the error
    /// sheet opens once the entry sheet is fully gone.
    private func presentError(photoData: Data?) {
        pendingError = ErrorRoute(photoData: photoData)
        isPresented = false
    }

    /// The entry sheet dismissed — promote whichever step is pending (map wins;
    /// otherwise the location-error sheet).
    private func onEntryDismissed() {
        if let pending {
            route = pending
            self.pending = nil
        } else if let pendingError {
            errorRoute = pendingError
            self.pendingError = nil
        }
    }

    /// The error sheet dismissed — reopen the entry sheet if the user chose
    /// "pick a different photo".
    private func onErrorDismissed() {
        guard pendingReopen else { return }
        pendingReopen = false
        isPresented = true
    }

    /// Opens the system Settings so the user can grant location access (the
    /// in-app prompt won't re-appear once denied). iOS only; no-op elsewhere.
    private func openLocationSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    // MARK: - Photo routing

    /// Where a picked photo should take the user, from its EXIF coordinate and the
    /// current location authorization. Pure so it's unit-testable.
    enum PhotoEntryRoute: Equatable {
        /// Open the map seeded with this coordinate (`nil` → the map adopts the
        /// device location as its fallback).
        case map(CLLocationCoordinate2D?)
        /// No usable GPS and permission not yet asked — request it, then map(nil).
        case requestLocationThenMap
        /// No usable GPS and location is denied/restricted — show the error sheet.
        case locationError

        nonisolated static func == (lhs: PhotoEntryRoute, rhs: PhotoEntryRoute) -> Bool {
            switch (lhs, rhs) {
            case (.requestLocationThenMap, .requestLocationThenMap),
                 (.locationError, .locationError):
                return true
            case let (.map(a), .map(b)):
                return a?.latitude == b?.latitude && a?.longitude == b?.longitude
            default:
                return false
            }
        }
    }

    /// Reuses `CreateMapViewModel.sanitized` to reject missing / null-island GPS.
    nonisolated static func photoRoute(coordinate: CLLocationCoordinate2D?,
                                       authorization: CLAuthorizationStatus) -> PhotoEntryRoute {
        if let valid = CreateMapViewModel.sanitized(coordinate) {
            return .map(valid)
        }
        switch authorization {
        case .notDetermined:
            return .requestLocationThenMap
        #if os(macOS)
        case .authorized, .authorizedAlways:
            return .map(nil)
        #else
        case .authorizedWhenInUse, .authorizedAlways:
            return .map(nil)
        #endif
        default:
            return .locationError
        }
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
            .enableSwipeBack()
        }
        .onChange(of: review.phase) { _, phase in
            if phase == .success { onSucceeded() }
        }
    }
}

// MARK: - Success host

/// Hosts `SuccessScreen` and drives its Save affordance: tapping the bookmark
/// opens the shared `SaveToListSheet`, and the filled/empty state is derived from
/// the app-wide `SavedStore` (so it reflects real list membership and updates as
/// soon as the sheet commits). A cover's content closure can't hold `@State`,
/// hence this wrapper.
private struct SuccessHost: View {
    let review: CreateReviewViewModel
    var onSeeSpot: () -> Void
    var onDone: () -> Void

    /// Injected on `content` in `MainTabView`, inherited by this cover. Optional
    /// so previews (which don't inject it) still render.
    @Environment(SavedStore.self) private var store: SavedStore?
    @State private var showSaveSheet = false

    /// Filled when the just-created spot is in at least one list.
    private var isSaved: Bool {
        guard let id = review.resultSpotID else { return false }
        return store?.isSaved(id) ?? false
    }

    var body: some View {
        SuccessScreen(
            spotName: review.spotName,
            place: review.resultPlace,
            rating: review.draft.rating,
            photos: review.resultPhotos,
            isNewSpot: review.isNewSpot,
            isSaved: isSaved,
            onTapSave: { if review.resultSpotID != nil { showSaveSheet = true } },
            onSeeSpot: onSeeSpot,
            onDone: onDone
        )
        .sheet(isPresented: $showSaveSheet) {
            if let id = review.resultSpotID {
                SaveToListSheet(spotID: id)
            }
        }
    }
}
