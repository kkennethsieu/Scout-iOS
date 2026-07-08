import SwiftUI
import PhotosUI
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

/// The Create tab. A single `NavigationStack` whose root is `ShareLocationScreen`;
/// each flow step is *pushed* onto the path: map → write review → success → spot
/// detail. The bottom tab bar hides while the flow is active, so the user is
/// locked into it (and back / edge-swipe pops) — the same containment the old
/// modal covers gave, without the cover-sequencing.
///
/// The two entry choices route like so:
/// - **Photo** → its EXIF coordinate (if any) seeds the pin; missing/invalid GPS
///   falls back to the device location, or shows the location-error sheet when
///   location is denied.
/// - **Current location** → the device location seeds the pin.
///
/// A single per-attempt `CreateReviewViewModel` accumulates the new review as the
/// user advances; it's created on the entry choice so each attempt starts fresh.
struct CreateFlowHost: View {
    /// True while the Create tab is the selected tab — used to warm the location
    /// fix so it's ready the moment the user taps "use my current location".
    var isActive: Bool

    /// Injected on `MainTabView`, inherited here. Optional so previews don't crash.
    @Environment(TabBarVisibility.self) private var tabBarVisibility: TabBarVisibility?

    /// Action-level auth gate. Optional so previews (which don't inject it) run the
    /// action directly instead of crashing.
    @Environment(AuthGate.self) private var authGate: AuthGate?

    /// The pushed flow steps. The stack root is `ShareLocationScreen` (empty path).
    private enum Step: Hashable {
        case map
        case review
        case success
        case detail(spotID: String)
    }

    @State private var path: [Step] = []

    // Per-attempt flow state, created on the entry choice and cleared on exit so
    // each attempt starts clean.
    @State private var review: CreateReviewViewModel?
    @State private var entry: CreateMapViewModel.Entry?
    @State private var entryPhotoData: Data?

    // Photo picker.
    @State private var showPhotoPicker = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    // Location-error sheet (no usable photo GPS + denied location).
    @State private var showLocationError = false
    /// "Pick a different photo" tapped — reopen the picker once the error sheet
    /// has dismissed (a sheet and the picker can't overlap).
    @State private var pendingReopen = false

    /// Warmed while the Create tab is active so the current location is ready the
    /// moment the user taps "use my current location".
    @State private var location = LocationManager()

    /// Tracks our single outstanding tab-bar hide request so request/release stay
    /// balanced as the path grows and shrinks.
    @State private var didHideBar = false

    var body: some View {
        NavigationStack(path: $path) {
            ShareLocationScreen(
                onTapUpload: { requireAuth { showPhotoPicker = true } },
                onUseCurrentLocation: {
                    requireAuth {
                        // The user explicitly chose location, so prompt if needed. The
                        // coordinate is synchronous in DEBUG via the dev override;
                        // otherwise the map adopts the device location as it arrives.
                        location.requestPermission()
                        choose(.currentLocation(location.coordinate))
                    }
                }
            )
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .map:
                    if let entry, let review {
                        CreateMapScreen(entry: entry, photoData: entryPhotoData, review: review) {
                            path.append(.review)
                        }
                    }
                case .review:
                    if let review {
                        WriteReviewScreen(viewModel: review)
                    }
                case .success:
                    if let review {
                        SuccessHost(
                            review: review,
                            onSeeSpot: {
                                if let id = review.resultSpotID {
                                    path.append(.detail(spotID: id))
                                }
                            },
                            onDone: { endFlow() }
                        )
                    }
                case .detail(let spotID):
                    SpotDetailScreen(spotID: spotID)
                }
            }
            .enableSwipeBack()
        }
        .overlay {
            if isLoadingPhoto {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $pickedItem,
                      matching: .images,
                      photoLibrary: .shared())
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .onChange(of: isActive) { _, active in
            if active { location.start() }
        }
        // Submitting the review flips the accumulator to `.success`; replace the
        // path so the submitted form can't be swiped back into.
        .onChange(of: review?.phase) { _, phase in
            if phase == .success { path = [.success] }
        }
        // Hide the tab bar for the whole flow (path non-empty) and restore it when
        // we return to the entry screen — keeping the counter balanced.
        .onChange(of: path.isEmpty) { _, empty in
            if !empty && !didHideBar {
                tabBarVisibility?.requestHidden()
                didHideBar = true
            } else if empty && didHideBar {
                tabBarVisibility?.releaseHidden()
                didHideBar = false
            }
        }
        .sheet(isPresented: $showLocationError, onDismiss: onErrorDismissed) {
            LocationErrorSheet(
                onPickDifferentPhoto: {
                    // Reopen the photo picker once this sheet dismisses.
                    pendingReopen = true
                    showLocationError = false
                },
                onEnableLocation: {
                    openLocationSettings()
                    showLocationError = false
                }
            )
        }
    }

    // MARK: - Entry

    /// Gates a create action behind sign-in: runs it directly when the gate isn't
    /// injected (previews), otherwise defers to `AuthGate` (present sign-in if
    /// needed, then run).
    private func requireAuth(_ action: @escaping () -> Void) {
        guard let authGate else { action(); return }
        authGate.require(action)
    }

    /// Loads the chosen photo as raw `Data`, then routes it.
    private func load(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            pickedItem = nil   // allow re-picking the same asset next time
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        handlePhotoPicked(data)
    }

    /// Routes a picked photo by its EXIF coordinate and the current authorization.
    private func handlePhotoPicked(_ data: Data) {
        let coordinate = PhotoMetadata(data: data).coordinate
        switch Self.photoRoute(coordinate: coordinate,
                               authorization: location.authorizationStatus) {
        case .map(let seed):
            choose(.photo(seed), photoData: data)
        case .requestLocationThenMap:
            // Permission not asked yet — prompt, then let the map adopt the device
            // location as its fallback.
            location.requestPermission()
            choose(.photo(nil), photoData: data)
        case .locationError:
            showLocationError = true
        }
    }

    /// Records the choice, creates the review accumulator, and pushes the map.
    private func choose(_ entry: CreateMapViewModel.Entry, photoData: Data? = nil) {
        review = Self.makeReview(entry: entry, photoData: photoData)
        self.entry = entry
        entryPhotoData = photoData
        path = [.map]
    }

    /// Tears down the attempt and returns to the entry screen on the Create tab.
    private func endFlow() {
        path = []
        review = nil
        entry = nil
        entryPhotoData = nil
    }

    /// The error sheet dismissed — reopen the photo picker if the user chose "pick
    /// a different photo".
    private func onErrorDismissed() {
        guard pendingReopen else { return }
        pendingReopen = false
        showPhotoPicker = true
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

    // MARK: - Review accumulator

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

// MARK: - Success host

/// Hosts `SuccessScreen` and drives its Save affordance: tapping the bookmark
/// opens the shared `SaveToListSheet`, and the filled/empty state is derived from
/// the app-wide `SavedStore` (so it reflects real list membership and updates as
/// soon as the sheet commits). A `navigationDestination` content closure can't
/// hold `@State`, hence this wrapper.
private struct SuccessHost: View {
    let review: CreateReviewViewModel
    var onSeeSpot: () -> Void
    var onDone: () -> Void

    /// Injected on `MainTabView`, inherited here. Optional so previews (which
    /// don't inject it) still render.
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
