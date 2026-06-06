import SwiftUI
import CoreLocation
import Observation

/// Single source of truth for a new review as it moves through the create flow
/// (map step → name picker → review form → submit). Holds the spot identity, the
/// context captured at the map step (coordinate / region / photos), every editable
/// form field, and the submission state.
///
/// The map step decides the `Target`: tapping a nearby pin reviews an existing
/// spot; "continue with new spot" creates one whose name is filled in at the
/// Name Picker. The backend create endpoint is multipart and takes `name`, `lat`,
/// `lng`, the review fields, and up to `maxPhotos` photos — so a new spot and its
/// first review are submitted together. Submission is stubbed until the endpoint
/// is wired; `makePayload()` already maps the form fields to it.
@Observable
@MainActor
final class CreateReviewViewModel {

    /// What the review is attached to.
    enum Target: Equatable {
        /// Tapped a nearby existing spot — already in the DB.
        case existingSpot(id: String, name: String)
        /// A brand-new spot; `name` starts empty and is set at the Name Picker.
        case newSpot(name: String)
    }

    /// Submission lifecycle for the footer button / overlays.
    enum SubmitPhase: Equatable {
        case idle
        case submitting
        case success
        case failed(String)
    }

    // MARK: - Tunables / backend constraints

    /// The create endpoint accepts an array of photos; the UI caps it here.
    nonisolated static let maxPhotos = 3
    nonisolated static let maxNameLength = 200
    /// Backend `TEXT_MAX` for notes / gear / composition.
    nonisolated static let maxNotesLength = 2000

    // MARK: - Identity & context (fixed once the map step commits)

    private(set) var target: Target
    /// Where the spot sits — the map pin. Required to create a new spot
    /// (`lat`/`lng` are mandatory on the endpoint). Mutable so the map step (and
    /// a later "Change location") can revise it.
    private(set) var coordinate: CLLocationCoordinate2D?
    /// Human-readable region from the map step ("Portland, USA"), for the header.
    private(set) var regionText: String

    /// Photos for the review, capped at `maxPhotos`. Seeded with the originally
    /// uploaded photo (if the user came in via photo upload).
    private(set) var photos: [Data]

    // MARK: - Form fields

    var draft = ReviewDraft()

    private(set) var phase: SubmitPhase = .idle

    /// Backend dependency for submission. Injectable for tests/previews.
    private let service: SpotService

    // MARK: - Options (ordered to match the mockup, not `allCases`)

    nonisolated static let timeOptions: [TimeOfDay] = [.goldenHour, .blueHour, .sunrise, .night, .midday]
    nonisolated static let seasonOptions: [Season] = [.spring, .summer, .fall, .winter, .yearRound]
    nonisolated static let accessOptions = ["Easy", "Moderate", "Hard"]

    // MARK: - Init

    init(target: Target,
         coordinate: CLLocationCoordinate2D? = nil,
         regionText: String = "",
         photoData: Data? = nil,
         service: SpotService = AppServices.spot) {
        self.target = target
        self.coordinate = coordinate
        self.regionText = regionText
        self.photos = Array((photoData.map { [$0] } ?? []).prefix(Self.maxPhotos))
        self.service = service
    }

    // MARK: - Derived

    /// Name shown in the form's LOCATION block — resolves from the target.
    var spotName: String {
        switch target {
        case .existingSpot(_, let name): name
        case .newSpot(let name): name
        }
    }

    var isNewSpot: Bool {
        if case .newSpot = target { return true }
        return false
    }

    var isSubmitting: Bool { phase == .submitting }

    /// Whether another photo can still be added.
    var canAddPhoto: Bool { photos.count < Self.maxPhotos }

    /// Whether the form is complete enough to submit.
    var canSubmit: Bool {
        Self.canSubmit(rating: draft.rating, name: spotName, hasPhotos: !photos.isEmpty,
                       hasLocation: coordinate.map(CLLocationCoordinate2DIsValid) ?? false)
    }

    /// One-line explanation of what's still blocking submission, or nil when ready
    /// — shown under the disabled Submit button. Ordered by how likely each is to
    /// be the actual blocker (a missing photo is the common one).
    var submitHint: String? {
        guard !canSubmit else { return nil }
        if photos.isEmpty { return "Add at least one photo to post." }
        if spotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Name this spot to post."
        }
        if coordinate.map(CLLocationCoordinate2DIsValid) != true {
            return "Set the spot location to post."
        }
        return "Add a rating to post."
    }

    // MARK: - Pure logic (unit-tested)

    /// Mirrors the endpoint's required constraints: `overall_rating` 1…5, at least
    /// one photo (`photo_urls` is required), a non-empty spot name within the
    /// length cap, and a valid coordinate (the spot's `lat`/`lng`). Everything
    /// else — including notes — is optional on the backend.
    nonisolated static func canSubmit(rating: Int, name: String, hasPhotos: Bool, hasLocation: Bool) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...5).contains(rating)
            && hasPhotos
            && !trimmedName.isEmpty && trimmedName.count <= maxNameLength
            && hasLocation
    }

    // MARK: - Photo actions

    func addPhoto(_ data: Data) {
        guard canAddPhoto else { return }
        photos.append(data)
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        photos.remove(at: index)
    }

    // MARK: - Actions

    /// Records the final pin from the map step (also used by "Change location").
    func place(coordinate: CLLocationCoordinate2D, regionText: String) {
        self.coordinate = coordinate
        self.regionText = regionText
    }

    /// Map step: the user tapped a nearby existing spot to review it.
    func reviewExisting(id: String, name: String) {
        target = .existingSpot(id: id, name: name)
    }

    /// Name Picker: the user chose a nearby place or typed their own name.
    func setNewSpotName(_ name: String) {
        target = .newSpot(name: name)
    }

    /// Maps the current draft onto the multipart submission payload. Times and
    /// seasons are emitted in canonical order as their raw backend strings; the
    /// tristate logistics pass through as `Bool?` (nil = unanswered).
    func makePayload() -> NewReviewPayload {
        NewReviewPayload(
            name: spotName.trimmingCharacters(in: .whitespacesAndNewlines),
            lat: coordinate?.latitude ?? 0,
            lng: coordinate?.longitude ?? 0,
            overallRating: draft.rating,
            notes: draft.notes,
            bestTimeOfDay: Self.timeOptions.filter { draft.times.contains($0) }.map(\.rawValue),
            bestSeason: Self.seasonOptions.filter { draft.seasons.contains($0) }.map(\.rawValue),
            accessLevel: draft.accessLevel,
            entranceFee: draft.entranceFee,
            crowdLevel: draft.crowdLevel,
            gearRecommendations: draft.gear,
            compositionHints: draft.compositionHint,
            permitRequired: draft.permitRequired,
            droneAllowed: draft.droneAllowed,
            tripodAllowed: draft.tripodAllowed,
            photos: photos
        )
    }

    func submit() async {
        guard canSubmit else { return }
        phase = .submitting
        do {
            switch target {
            case .existingSpot(let id, _):
                // Wired: multipart POST /spots/{id}/reviews. The returned review
                // is discarded for now — SuccessScreen is still fed from the draft.
                _ = try await service.submitReview(spotID: id, payload: makePayload())
            case .newSpot:
                // Wired: multipart POST /spots/with-review. The backend
                // reverse-geocodes the coordinate and returns {spot, review};
                // discarded for now — SuccessScreen is still fed from the draft.
                _ = try await service.submitNewSpot(payload: makePayload())
            }
            phase = .success
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Submission payload

/// The multipart body for creating a spot + its first review. Field names map to
/// the endpoint's `Form`/`File` parameters (snake_case at encode time). The
/// optional vocabularies (`accessLevel`, `crowdLevel`) and tristate logistics are
/// `nil` when unanswered; `bestSeason` is list-shaped like `bestTimeOfDay`.
nonisolated struct NewReviewPayload: Equatable {
    let name: String
    let lat: Double
    let lng: Double
    let overallRating: Int
    let notes: String
    let bestTimeOfDay: [String]
    let bestSeason: [String]
    let accessLevel: String?
    let entranceFee: String
    let crowdLevel: String?
    let gearRecommendations: String
    let compositionHints: String
    let permitRequired: Bool?
    let droneAllowed: Bool?
    let tripodAllowed: Bool?
    let photos: [Data]
}

// MARK: - Create response

/// The decoded body of `POST /spots/with-review` — the backend's
/// `SubmitReviewWithNewSpotResponse`, carrying the saved spot and its first
/// review.
nonisolated struct CreatedSpotReview: Decodable {
    let spot: SpotDetail
    let review: Review
}
