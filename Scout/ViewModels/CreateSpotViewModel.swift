import SwiftUI
import CoreLocation
import Observation

/// Coordinator for the create-spot flow. Owns the navigation `path`, a working
/// `draft`, and the intent methods that advance the flow (the edges of the
/// state machine). All branching lives here so the flow is testable without UI;
/// the sheets/screens are pure presentation that call these intents.
@Observable
@MainActor
final class CreateSpotViewModel {
    /// The pushed steps on top of the `share` root.
    var path: [CreateStep] = []
    /// The sheet's current detent, driven by the top step.
    var detent: PresentationDetent = CreateSpotViewModel.shareDetent
    /// True while extracting EXIF / looking up nearby spots.
    private(set) var isWorking = false
    /// Set by terminal intents to ask the container to close the sheet.
    private(set) var requestClose = false

    private var draft = SpotDraft()
    private let service: SpotService

    /// Radius for the "is there already a spot here?" lookup (~150 m).
    var searchRadiusKm: Double = 0.15

    init(service: SpotService = AppServices.spot) {
        self.service = service
    }

    // MARK: - Detents

    static let shareDetent: PresentationDetent = .height(420)
    let detents: Set<PresentationDetent> = [
        .height(420), .height(460), .height(560), .large,
    ]

    // MARK: - Intents

    /// A photo was picked: read its EXIF, then look up nearby spots if it has
    /// GPS, otherwise show the location-error path.
    func pickedPhoto(_ data: Data) async {
        isWorking = true
        defer { isWorking = false }

        let metadata = await Task.detached { PhotoMetadata(data: data) }.value
        draft.photoData = data
        draft.metadata = metadata
        draft.source = .photoUpload

        guard let coordinate = metadata.coordinate else {
            go(to: .locationError(.photoUpload))
            return
        }
        draft.coordinate = coordinate
        await lookup(source: .photoUpload, coordinate: coordinate)
    }

    /// The user chose "use my current location"; route to the precise-location
    /// screen (or the error path if we have no device coordinate).
    func choseCurrentLocation(coordinate: CLLocationCoordinate2D?) {
        draft.source = .currentLocation
        guard let coordinate else {
            go(to: .locationError(.currentLocation))
            return
        }
        draft.coordinate = coordinate
        go(to: .confirmLocation)
    }

    /// The precise location was confirmed on the map (Phase 2).
    func confirmedLocation(_ coordinate: CLLocationCoordinate2D) async {
        draft.coordinate = coordinate
        await lookup(source: .currentLocation, coordinate: coordinate)
    }

    // Terminal actions — these advance to the review flow in Phase 2; for now
    // they close the create flow.
    func selectedNearby(_ spot: NearbySpot) {
        draft.chosenSpot = spot
        finish()
    }

    func confirmedSame(_ spot: NearbySpot) {
        draft.chosenSpot = spot
        finish()
    }

    func createNew() {
        finish()
    }

    /// "No, this is a different spot" — back to the start of the flow.
    func differentSpot() {
        path.removeAll()
        syncDetent()
    }

    /// Primary recovery action on the location-error sheet.
    func errorPrimary() {
        switch draft.source {
        case .photoUpload:
            // Try the current-location path instead.
            go(to: .confirmLocation)
        case .currentLocation:
            // Go back to the start to upload a photo.
            path.removeAll()
            syncDetent()
        }
    }

    func pickOnMap() {
        go(to: .confirmLocation)
    }

    func cancel() {
        finish()
    }

    private func finish() {
        requestClose = true
    }

    /// Resets the machine. Call from the sheet's `onDismiss`.
    func reset() {
        path.removeAll()
        draft = SpotDraft()
        isWorking = false
        requestClose = false
        detent = Self.shareDetent
    }

    // MARK: - Lookup

    private func lookup(source: LocationErrorSheet.Source,
                        coordinate: CLLocationCoordinate2D) async {
        let region = SpotRegion(latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                radiusKm: searchRadiusKm)
        do {
            let spots = try await service.fetchSpots(near: region)
            let nearby = spots
                .map { mapToNearby($0, from: coordinate) }
                .sorted { $0.distanceMeters < $1.distanceMeters }
            draft.candidates = nearby

            switch nearby.count {
            case 0:  go(to: .locationError(source))
            case 1:  go(to: .sameSpot(nearby[0]))
            default: go(to: .nearbySpots(nearby))
            }
        } catch {
            go(to: .locationError(source))
        }
    }

    private func mapToNearby(_ spot: SpotSummary,
                             from origin: CLLocationCoordinate2D) -> NearbySpot {
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let spotLocation = CLLocation(latitude: spot.publicLat, longitude: spot.publicLng)
        let meters = originLocation.distance(from: spotLocation)
        return NearbySpot(
            id: spot.id,
            name: spot.name,
            thumbnailURL: spot.coverPhoto,
            distance: Self.distanceText(meters),
            category: spot.city,
            distanceMeters: meters
        )
    }

    // MARK: - Navigation helpers

    private func go(to step: CreateStep) {
        path.append(step)
        detent = preferredDetent(for: step)
    }

    /// Re-derives the detent from the top step (e.g. after a back-swipe).
    func syncDetent() {
        detent = preferredDetent(for: path.last)
    }

    private func preferredDetent(for step: CreateStep?) -> PresentationDetent {
        switch step {
        case .none:                         Self.shareDetent
        case .confirmLocation, .nearbySpots: .large
        case .sameSpot:                     .height(560)
        case .locationError:                .height(460)
        }
    }

    static func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded()))m away"
        }
        let km = meters / 1000
        return "\(km.formatted(.number.precision(.fractionLength(1))))km away"
    }
}
