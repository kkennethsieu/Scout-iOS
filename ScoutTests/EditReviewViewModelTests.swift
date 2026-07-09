import Testing
import Foundation
@testable import Scout

/// Covers `EditReviewViewModel`: prefilling the draft from an existing review, the
/// save gate, and the `updateReview` (PATCH) save path.
@MainActor
struct EditReviewViewModelTests {

    // MARK: - Prefill

    @Test func prefillsDraftFromReview() {
        let review = Review.samples[0]   // rating 5, times [GoldenHour, Sunrise], seasons [Spring, Fall]
        let vm = EditReviewViewModel(review: review, service: StubEditService())

        #expect(vm.reviewID == review.id)
        #expect(vm.spotName == review.spotName)
        #expect(vm.draft.rating == 5)
        #expect(vm.draft.notes == review.notes)
        #expect(vm.draft.times == Set([.goldenHour, .sunrise]))
        #expect(vm.draft.seasons == Set([.spring, .fall]))
        #expect(vm.draft.accessLevel == "Moderate")
        #expect(vm.draft.tripodAllowed == true)
        #expect(vm.draft.entranceFee == "0")
    }

    @Test func spotNameFallsBackToCityWhenMissing() {
        var review = Review.samples[0]
        review = Review(id: review.id, spotId: review.spotId, spotName: nil,
                        publicLat: 0, publicLng: 0, city: "Portland", adminArea: "OR",
                        userId: review.userId, authorName: nil, authorPhotoUrl: nil, photoUrls: [],
                        overallRating: 3, notes: nil, bestTimeOfDay: [], bestSeason: [],
                        accessLevel: nil, entranceFee: nil, crowdLevel: nil,
                        gearRecommendations: nil, compositionHints: nil,
                        permitRequired: nil, droneAllowed: nil, tripodAllowed: nil,
                        createdAt: Date())
        let vm = EditReviewViewModel(review: review, service: StubEditService())
        #expect(vm.spotName == "Portland, OR")
    }

    // MARK: - Change tracking (discard guard)

    @Test func hasNoChangesWhenUntouched() {
        let vm = EditReviewViewModel(review: Review.samples[0], service: StubEditService())
        #expect(vm.hasChanges == false)
    }

    @Test func hasChangesAfterEditingAField() {
        let vm = EditReviewViewModel(review: Review.samples[0], service: StubEditService())
        vm.draft.notes += " — updated"
        #expect(vm.hasChanges)
    }

    @Test func hasNoChangesAfterRevertingEdit() {
        let vm = EditReviewViewModel(review: Review.samples[0], service: StubEditService())
        let original = vm.draft.rating
        vm.draft.rating = original == 5 ? 4 : 5
        #expect(vm.hasChanges)
        vm.draft.rating = original
        #expect(vm.hasChanges == false)   // back to baseline
    }

    // MARK: - Save gate

    @Test func canSaveRequiresValidRating() {
        let vm = EditReviewViewModel(review: Review.samples[0], service: StubEditService())
        #expect(vm.canSave)
        #expect(vm.saveHint == nil)

        vm.draft.rating = 0
        #expect(vm.canSave == false)
        #expect(vm.saveHint == "Add a rating to save.")
    }

    // MARK: - Save

    @Test func saveCallsUpdateReviewAndReturnsUpdated() async {
        let stub = StubEditService(result: Review.samples[1])
        let vm = EditReviewViewModel(review: Review.samples[0], service: stub)
        vm.draft.notes = "Revised notes"

        let updated = await vm.save()

        #expect(updated?.id == Review.samples[1].id)
        #expect(vm.phase == .saved)
        #expect(stub.recorded?.reviewID == Review.samples[0].id)   // PATCHed the right review
        #expect(stub.recorded?.payload.notes == "Revised notes")   // sent the edited draft
    }

    @Test func saveFailureSetsFailedPhaseAndReturnsNil() async {
        let stub = StubEditService(error: SpotServiceError.invalidResponse)
        let vm = EditReviewViewModel(review: Review.samples[0], service: stub)

        let updated = await vm.save()

        #expect(updated == nil)
        if case .failed = vm.phase {} else {
            Issue.record("expected .failed phase, got \(vm.phase)")
        }
    }

    @Test func saveIsNoOpWhenRatingInvalid() async {
        let stub = StubEditService()
        let vm = EditReviewViewModel(review: Review.samples[0], service: stub)
        vm.draft.rating = 0

        let updated = await vm.save()

        #expect(updated == nil)
        #expect(stub.recorded == nil)         // never reached the service
        #expect(vm.phase == .editing)
    }
}

// MARK: - Stub service

private nonisolated final class StubEditService: SpotService, @unchecked Sendable {
    struct Call { let reviewID: String; let payload: NewReviewPayload }

    var result: Review
    var error: Error?
    private(set) var recorded: Call?

    init(result: Review = Review.samples[0], error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        PaginatedSpots(items: [], limit: limit, nextCursor: nil)
    }
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] { [] }
    func fetchSpotDetail(id: String) async throws -> SpotDetail { .sample }
    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review { result }
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        CreatedSpotReview(spot: .sample, review: result)
    }
    func updateReview(reviewID: String, payload: NewReviewPayload) async throws -> Review {
        recorded = Call(reviewID: reviewID, payload: payload)
        if let error { throw error }
        return result
    }
}
