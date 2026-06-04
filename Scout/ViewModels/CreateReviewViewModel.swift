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
    nonisolated static let maxNotesLength = 1000

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

    var rating: Int = 4
    var notes: String = ""
    var compositionHint: String = ""
    var gear: String = ""
    var times: Set<TimeOfDay> = []
    var environments: Set<String> = []
    var accessLevel: String = "Moderate"
    var permitRequired: Bool = false
    var droneAllowed: Bool = true
    var tripodAllowed: Bool = true
    var entranceFee: String = ""
    var crowdLevel: String = "Moderate"

    private(set) var phase: SubmitPhase = .idle

    // MARK: - Options (ordered to match the mockup, not `allCases`)

    nonisolated static let timeOptions: [TimeOfDay] = [.goldenHour, .blueHour, .sunrise, .night, .midday]
    nonisolated static let environmentOptions = ["Forest", "Alpine", "Water", "Panoramic", "Coast"]
    nonisolated static let accessOptions = ["Easy", "Moderate", "Hard"]

    // MARK: - Init

    init(target: Target,
         coordinate: CLLocationCoordinate2D? = nil,
         regionText: String = "",
         photoData: Data? = nil) {
        self.target = target
        self.coordinate = coordinate
        self.regionText = regionText
        self.photos = Array((photoData.map { [$0] } ?? []).prefix(Self.maxPhotos))
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
        Self.canSubmit(rating: rating, name: spotName, notes: notes,
                       hasLocation: coordinate.map(CLLocationCoordinate2DIsValid) ?? false)
    }

    // MARK: - Pure logic (unit-tested)

    /// Mirrors the endpoint's required constraints: rating 1…5, a non-empty name
    /// within the length cap, non-empty notes within the cap, and a valid
    /// coordinate (the spot's `lat`/`lng`).
    nonisolated static func canSubmit(rating: Int, name: String, notes: String, hasLocation: Bool) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...5).contains(rating)
            && !trimmedName.isEmpty && trimmedName.count <= maxNameLength
            && !trimmedNotes.isEmpty && trimmedNotes.count <= maxNotesLength
            && hasLocation
    }

    /// The backend stores a single environment; pick the first selected one in
    /// canonical option order so the result is deterministic.
    nonisolated static func primaryEnvironment(from selected: Set<String>) -> String {
        environmentOptions.first { selected.contains($0) } ?? ""
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

    /// Maps the current draft onto the multipart submission payload. Times are
    /// emitted in canonical order as their raw backend strings; environments
    /// collapse to the backend's single value; the optional text fields default
    /// to `""` (the endpoint's default), never null.
    func makePayload() -> NewReviewPayload {
        NewReviewPayload(
            name: spotName.trimmingCharacters(in: .whitespacesAndNewlines),
            lat: coordinate?.latitude ?? 0,
            lng: coordinate?.longitude ?? 0,
            overallRating: rating,
            notes: notes,
            bestTimeOfDay: Self.timeOptions.filter { times.contains($0) }.map(\.rawValue),
            accessLevel: accessLevel,
            entranceFee: entranceFee,
            crowdLevel: crowdLevel,
            environment: Self.primaryEnvironment(from: environments),
            gearRecommendations: gear,
            compositionHints: compositionHint,
            permitRequired: permitRequired,
            droneAllowed: droneAllowed,
            tripodAllowed: tripodAllowed,
            photos: photos
        )
    }

    func submit() async {
        guard canSubmit else { return }
        phase = .submitting
        // TODO: POST `makePayload()` as multipart/form-data once the endpoint is
        // wired into SpotService. Stubbed success for now.
        _ = makePayload()
        phase = .success
    }
}

// MARK: - Submission payload

/// The multipart body for creating a spot + its first review. Field names map to
/// the endpoint's `Form`/`File` parameters (snake_case at encode time). The
/// optional text fields are `""` when unset (the endpoint's default), not null.
nonisolated struct NewReviewPayload: Equatable {
    let name: String
    let lat: Double
    let lng: Double
    let overallRating: Int
    let notes: String
    let bestTimeOfDay: [String]
    let accessLevel: String
    let entranceFee: String
    let crowdLevel: String
    let environment: String
    let gearRecommendations: String
    let compositionHints: String
    let permitRequired: Bool
    let droneAllowed: Bool
    let tripodAllowed: Bool
    let photos: [Data]
}
