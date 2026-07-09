import Testing
import CoreLocation
import Foundation
@testable import Scout

/// Covers `CreateReviewViewModel`: spot-identity resolution, the submit-gate
/// validation (mirroring the endpoint's constraints), the photo cap, and the
/// payload mapping onto the multipart create endpoint.
@MainActor
struct CreateReviewViewModelTests {

    private let coordinate = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)

    private func makeVM(target: CreateReviewViewModel.Target = .newSpot(name: "Emerald Basin"),
                        photoData: Data? = nil,
                        service: SpotService = MockSpotService()) -> CreateReviewViewModel {
        CreateReviewViewModel(target: target, coordinate: coordinate,
                              regionText: "Portland, USA", photoData: photoData, service: service)
    }

    // MARK: - Target / identity

    @Test func spotNameResolvesFromTarget() {
        #expect(makeVM(target: .newSpot(name: "Emerald Basin")).spotName == "Emerald Basin")
        #expect(makeVM(target: .existingSpot(id: "1", name: "Cedar Cathedral")).spotName == "Cedar Cathedral")
    }

    @Test func isNewSpotReflectsTarget() {
        #expect(makeVM(target: .newSpot(name: "X")).isNewSpot)
        #expect(makeVM(target: .existingSpot(id: "1", name: "X")).isNewSpot == false)
    }

    @Test func setNewSpotNameUpdatesTargetAndName() {
        let vm = makeVM(target: .newSpot(name: ""))
        vm.setNewSpotName("Bixby Creek Bridge")
        #expect(vm.spotName == "Bixby Creek Bridge")
        #expect(vm.isNewSpot)
    }

    @Test func reviewExistingSwitchesTarget() {
        let vm = makeVM(target: .newSpot(name: ""))
        vm.reviewExisting(id: "42", name: "Cedar Cathedral")
        #expect(vm.isNewSpot == false)
        #expect(vm.spotName == "Cedar Cathedral")
        #expect(vm.target == .existingSpot(id: "42", name: "Cedar Cathedral"))
    }

    @Test func placeUpdatesCoordinateAndRegion() {
        let vm = CreateReviewViewModel(target: .newSpot(name: "X"), coordinate: nil)
        #expect(vm.coordinate == nil)
        let pin = CLLocationCoordinate2D(latitude: 46.5572, longitude: 8.5614)
        vm.place(coordinate: pin, regionText: "Andermatt, Switzerland")
        #expect(vm.coordinate?.latitude == pin.latitude)
        #expect(vm.coordinate?.longitude == pin.longitude)
        #expect(vm.regionText == "Andermatt, Switzerland")
        #expect(vm.makePayload().lat == pin.latitude)   // now flows into the payload
    }

    // MARK: - Submit gate

    @Test func canSubmitTrueWhenComplete() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "Emerald Basin",
                                                hasPhotos: true, hasLocation: true))
    }

    @Test func canSubmitFalseOnEmptyOrWhitespaceName() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "  ", hasPhotos: true, hasLocation: true) == false)
    }

    @Test func canSubmitFalseWithoutPhoto() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "X", hasPhotos: false, hasLocation: true) == false)
    }

    @Test func canSubmitFalseOnRatingOutOfRange() {
        #expect(CreateReviewViewModel.canSubmit(rating: 0, name: "X", hasPhotos: true, hasLocation: true) == false)
        #expect(CreateReviewViewModel.canSubmit(rating: 6, name: "X", hasPhotos: true, hasLocation: true) == false)
    }

    @Test func canSubmitFalseWithoutLocation() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "X", hasPhotos: true, hasLocation: false) == false)
    }

    @Test func canSubmitFalseWhenNameExceedsCap() {
        let longName = String(repeating: "a", count: CreateReviewViewModel.maxNameLength + 1)
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: longName, hasPhotos: true, hasLocation: true) == false)
    }

    @Test func canSubmitTrueWithoutNotes() {
        // Notes are optional now — a photo + rating + spot is enough.
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "X", hasPhotos: true, hasLocation: true))
    }

    @Test func submitHintPrioritizesMissingPhotoThenClears() {
        let vm = makeVM(target: .newSpot(name: "Emerald Basin"))   // name + coord, no photo
        vm.draft.rating = 5                  // isolate the photo as the only blocker
        #expect(vm.submitHint == "Add at least one photo to post.")
        vm.addPhoto(Data([0x1]))
        #expect(vm.submitHint == nil)        // ready → no hint
    }

    @Test func submitHintAsksForRatingWhenOnlyRatingMissing() {
        let vm = makeVM(photoData: Data([0x1]))   // photo + name + coord, rating still 0
        #expect(vm.submitHint == "Add a rating to post.")
    }

    @Test func submitHintNilWhenReady() {
        let vm = makeVM(photoData: Data([0x1]))
        vm.draft.rating = 4
        #expect(vm.canSubmit)
        #expect(vm.submitHint == nil)
    }

    @Test func instanceCanSubmitRequiresPhotoAndCoordinate() {
        let noPhoto = makeVM(target: .newSpot(name: "Emerald Basin"))
        #expect(noPhoto.canSubmit == false)   // no photo

        let noCoord = CreateReviewViewModel(target: .newSpot(name: "Emerald Basin"),
                                            coordinate: nil, photoData: Data([0x1]))
        #expect(noCoord.canSubmit == false)   // no coordinate → can't create the spot

        let ready = makeVM(target: .newSpot(name: "Emerald Basin"), photoData: Data([0x1]))
        ready.draft.rating = 4
        #expect(ready.canSubmit)
    }

    // MARK: - Photos (capped, seeded)

    @Test func photosSeedFromUploadedPhoto() {
        let vm = makeVM(photoData: Data([0x1]))
        #expect(vm.photos.count == 1)
    }

    @Test func addPhotoStopsAtCap() {
        let vm = makeVM()
        for i in 0..<(CreateReviewViewModel.maxPhotos + 2) {
            vm.addPhoto(Data([UInt8(i)]))
        }
        #expect(vm.photos.count == CreateReviewViewModel.maxPhotos)
        #expect(vm.canAddPhoto == false)
    }

    @Test func removePhotoDropsAtIndex() {
        let vm = makeVM()
        vm.addPhoto(Data([0x1]))
        vm.addPhoto(Data([0x2]))
        vm.removePhoto(at: 0)
        #expect(vm.photos == [Data([0x2])])
        #expect(vm.canAddPhoto)
        vm.removePhoto(at: 5)   // out of range → no-op
        #expect(vm.photos.count == 1)
    }

    // MARK: - Payload mapping

    @Test func payloadMapsFieldsAndLocation() {
        let vm = makeVM(target: .newSpot(name: "  Emerald Basin  "), photoData: Data([0x9]))
        vm.draft.rating = 5
        vm.draft.notes = "Lovely light"
        vm.draft.times = [.sunrise, .goldenHour]      // out of canonical order on purpose
        vm.draft.seasons = [.fall, .spring]           // out of canonical order on purpose
        vm.draft.permitRequired = nil                 // unanswered stays nil
        vm.draft.droneAllowed = false
        vm.draft.gear = ""
        vm.draft.compositionHint = ""

        let payload = vm.makePayload()
        #expect(payload.name == "Emerald Basin")                 // trimmed
        #expect(payload.lat == coordinate.latitude)
        #expect(payload.lng == coordinate.longitude)
        #expect(payload.overallRating == 5)
        #expect(payload.bestTimeOfDay == ["GoldenHour", "Sunrise"])  // canonical order, raw values
        #expect(payload.bestSeason == ["Spring", "Fall"])            // canonical order, raw values
        #expect(payload.permitRequired == nil)
        #expect(payload.droneAllowed == false)
        #expect(payload.gearRecommendations == "")               // default, not nil
        #expect(payload.compositionHints == "")
        #expect(payload.photos.count == 1)
    }

    /// The create form's `access_level` / `crowd_level` options are sent verbatim
    /// as multipart values and must match the backend's `Literal` vocabularies, or
    /// `POST /spots/with-review` 422s. (Time/season raw values are covered by their
    /// model enums.) See `Scout-backend/app/schemas/enums.py`.
    @Test func optionVocabulariesMatchBackendLiterals() {
        #expect(CreateReviewViewModel.accessOptions == ["Easy", "Moderate", "Difficult"])
        #expect(AccessLogisticsCard.defaultCrowdOptions == ["Empty", "Light", "Moderate", "Crowded"])
        #expect(Set(TimeOfDay.allCases.map(\.rawValue))
                == ["Sunrise", "GoldenHour", "BlueHour", "Midday", "Night"])
        #expect(Set(Season.allCases.map(\.rawValue))
                == ["Spring", "Summer", "Fall", "Winter", "YearRound"])
    }

    @Test func payloadParsesEntranceFee() {
        let vm = makeVM(photoData: Data([0x9]))
        vm.draft.rating = 5

        vm.draft.entranceFee = "12.50"
        #expect(vm.makePayload().entranceFee == 12.5)

        vm.draft.entranceFee = ""           // unanswered
        #expect(vm.makePayload().entranceFee == nil)

        vm.draft.entranceFee = "abc"        // unparseable → nil
        #expect(vm.makePayload().entranceFee == nil)
    }

    // MARK: - Submit lifecycle

    @Test func submitNewSpotCallsServiceAndSucceeds() async {
        let vm = makeVM(photoData: Data([0x1]), service: StubSpotService())   // .newSpot
        vm.draft.rating = 4
        await vm.submit()
        #expect(vm.phase == .success)
    }

    @Test func submitIsNoOpWhenInvalid() async {
        let vm = makeVM()
        // no photo → can't submit
        await vm.submit()
        #expect(vm.phase == .idle)
    }

    @Test func submitExistingSpotCallsServiceAndSucceeds() async {
        let service = StubSpotService()
        let vm = CreateReviewViewModel(target: .existingSpot(id: "1", name: "Cedar Cathedral"),
                                       coordinate: coordinate, regionText: "Portland, USA",
                                       photoData: Data([0x1]), service: service)
        vm.draft.rating = 4
        await vm.submit()
        #expect(vm.phase == .success)
    }

    @Test func submitSetsFailedOnServiceError() async {
        let service = StubSpotService(error: StubError.boom)
        let vm = CreateReviewViewModel(target: .existingSpot(id: "1", name: "Cedar Cathedral"),
                                       coordinate: coordinate, regionText: "Portland, USA",
                                       photoData: Data([0x1]), service: service)
        vm.draft.rating = 4
        await vm.submit()
        if case .failed = vm.phase {} else {
            Issue.record("expected .failed phase, got \(vm.phase)")
        }
    }

    // MARK: - Duplicate spot (409 → add review to existing)

    @Test func duplicateNewSpotErrorEntersDuplicatePhase() async {
        let dup = SpotServiceError.duplicateSpot(
            existingSpotID: "abc123", name: "Potato Harbor",
            message: "A spot named 'Potato Harbor' already exists nearby (12m away).")
        let vm = makeVM(photoData: Data([0x1]), service: StubSpotService(newSpotError: dup))
        vm.draft.rating = 4
        await vm.submit()
        #expect(vm.phase == .duplicate(CreateReviewViewModel.DuplicateSpot(
            id: "abc123", name: "Potato Harbor",
            message: "A spot named 'Potato Harbor' already exists nearby (12m away).")))
    }

    @Test func addReviewToExistingSpotResubmitsToExistingAndSucceeds() async {
        let dup = SpotServiceError.duplicateSpot(existingSpotID: "abc123",
                                                 name: "Potato Harbor", message: nil)
        // submitNewSpot 409s; submitReview (the re-submit) has no error → succeeds.
        let vm = makeVM(photoData: Data([0x1]), service: StubSpotService(newSpotError: dup))
        vm.draft.rating = 4
        await vm.submit()
        await vm.addReviewToExistingSpot()

        #expect(vm.phase == .success)
        #expect(vm.isNewSpot == false)                                   // re-targeted
        #expect(vm.resultSpotID == "abc123")                            // → the existing spot
        #expect(vm.target == .existingSpot(id: "abc123", name: "Potato Harbor"))
        #expect(vm.createdReview != nil)
    }

    @Test func addReviewToExistingSpotIsNoOpOutsideDuplicatePhase() async {
        let vm = makeVM(photoData: Data([0x1]), service: StubSpotService())
        vm.draft.rating = 4
        await vm.addReviewToExistingSpot()   // phase is .idle → guarded no-op
        #expect(vm.phase == .idle)
        #expect(vm.isNewSpot)                // target untouched
    }

    @Test func nonDuplicateNewSpotErrorStillFails() async {
        let vm = makeVM(photoData: Data([0x1]),
                        service: StubSpotService(newSpotError: SpotServiceError.http(status: 500)))
        vm.draft.rating = 4
        await vm.submit()
        if case .failed = vm.phase {} else {
            Issue.record("expected .failed phase, got \(vm.phase)")
        }
    }

    @Test func duplicateSpotResponseDecodesFlatBody() throws {
        let json = Data("""
        {"code":"SPOT_ALREADY_EXISTS",\
        "detail":"A spot named 'Potato Harbor' already exists nearby (12m away).",\
        "spot_id":"abc123","name":"Potato Harbor","distance_m":12.0}
        """.utf8)
        let dup = try JSONDecoder.scout.decode(LiveSpotService.DuplicateSpotResponse.self, from: json)
        #expect(dup.code == "SPOT_ALREADY_EXISTS")
        #expect(dup.spotId == "abc123")
        #expect(dup.name == "Potato Harbor")
        #expect(dup.detail == "A spot named 'Potato Harbor' already exists nearby (12m away).")
    }

    // MARK: - Already reviewed (409 → update existing review)

    @Test func alreadyReviewedErrorEntersPhase() async {
        let conflict = SpotServiceError.alreadyReviewed(spotID: "1", reviewID: "r9",
                                                        message: "You have already reviewed this spot.")
        let vm = CreateReviewViewModel(target: .existingSpot(id: "1", name: "Cedar Cathedral"),
                                       coordinate: coordinate, regionText: "Portland, USA",
                                       photoData: Data([0x1]), service: StubSpotService(submitReviewError: conflict))
        vm.draft.rating = 4
        await vm.submit()
        #expect(vm.phase == .alreadyReviewed(reviewID: "r9"))
    }

    @Test func updateExistingReviewPatchesAndSucceeds() async {
        let conflict = SpotServiceError.alreadyReviewed(spotID: "1", reviewID: "r9", message: nil)
        // submitReview 409s; updateReview (the PATCH) has no error → succeeds.
        let vm = CreateReviewViewModel(target: .existingSpot(id: "1", name: "Cedar Cathedral"),
                                       coordinate: coordinate, regionText: "Portland, USA",
                                       photoData: Data([0x1]), service: StubSpotService(submitReviewError: conflict))
        vm.draft.rating = 4
        await vm.submit()
        await vm.updateExistingReview()

        #expect(vm.phase == .success)
        #expect(vm.resultSpotID == "1")            // routes to the existing spot
        #expect(vm.isNewSpot == false)
        #expect(vm.createdReview != nil)
    }

    @Test func updateExistingReviewIsNoOpOutsideAlreadyReviewedPhase() async {
        let vm = makeVM(photoData: Data([0x1]), service: StubSpotService())
        vm.draft.rating = 4
        await vm.updateExistingReview()   // phase is .idle → guarded no-op
        #expect(vm.phase == .idle)
    }

    @Test func reviewAlreadyExistsResponseDecodesFlatBody() throws {
        let json = Data("""
        {"code":"REVIEW_ALREADY_EXISTS",\
        "detail":"You have already reviewed this spot.",\
        "spot_id":"1","review_id":"r9"}
        """.utf8)
        let existing = try JSONDecoder.scout.decode(LiveSpotService.ReviewAlreadyExistsResponse.self, from: json)
        #expect(existing.code == "REVIEW_ALREADY_EXISTS")
        #expect(existing.spotId == "1")
        #expect(existing.reviewId == "r9")
    }

    // MARK: - Result accessors (feed the success screen)

    @Test func newSpotResultUsesSavedSpot() async {
        // StubSpotService returns SpotDetail.sample (id "1", "Cascade Range, WA").
        let vm = makeVM(photoData: Data([0x1]), service: StubSpotService())   // .newSpot
        vm.draft.rating = 4
        await vm.submit()
        #expect(vm.createdSpot?.id == "1")
        #expect(vm.createdReview != nil)
        #expect(vm.resultSpotID == "1")
        #expect(vm.resultPlace == "Cascade Range, WA")   // backend-geocoded locality
        #expect(vm.resultPhotos == [Data([0x1])])         // local bytes, instant
    }

    @Test func existingSpotResultFallsBackToTargetAndRegion() async {
        let vm = CreateReviewViewModel(target: .existingSpot(id: "42", name: "Cedar Cathedral"),
                                       coordinate: coordinate, regionText: "Portland, USA",
                                       photoData: Data([0x1]), service: StubSpotService())
        vm.draft.rating = 4
        await vm.submit()
        #expect(vm.createdSpot == nil)                    // existing-spot endpoint returns no spot
        #expect(vm.createdReview != nil)
        #expect(vm.resultSpotID == "42")                  // from the target
        #expect(vm.resultPlace == "Portland, USA")        // falls back to the map region
    }

    @Test func resultsAreEmptyBeforeSubmit() {
        let vm = makeVM(photoData: Data([0x1]))
        #expect(vm.createdSpot == nil)
        #expect(vm.createdReview == nil)
        #expect(vm.resultSpotID == nil)                   // .newSpot, nothing saved yet
    }
}

// MARK: - Stub service

private enum StubError: Error { case boom }

private nonisolated struct StubSpotService: SpotService {
    var review: Review = Review.samples[0]
    var error: Error?
    /// Thrown from `submitNewSpot` only (falls back to `error`), so a test can make
    /// the new-spot create fail while the existing-spot re-submit still succeeds.
    var newSpotError: Error?
    /// Thrown from `submitReview` only (falls back to `error`), so a test can make
    /// the existing-spot review fail while `updateReview` still succeeds.
    var submitReviewError: Error?

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { SpotDetail.sample }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }

    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review {
        if let submitReviewError { throw submitReviewError }
        if let error { throw error }
        return review
    }
    func updateReview(reviewID: String, payload: NewReviewPayload) async throws -> Review {
        if let error { throw error }
        return review
    }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        if let newSpotError { throw newSpotError }
        if let error { throw error }
        return CreatedSpotReview(spot: .sample, review: review)
    }
}
