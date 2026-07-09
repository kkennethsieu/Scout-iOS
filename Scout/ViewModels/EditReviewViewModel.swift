import Foundation
import Observation

/// Drives the edit-review form (`EditReviewScreen`). Seeds a `ReviewDraft` from an
/// existing `Review` and saves changes via `PATCH /reviews/{id}` (text/attributes
/// only — photos aren't editable on that endpoint). The spot is fixed, so there's
/// no location/name editing here.
@Observable
@MainActor
final class EditReviewViewModel {

    enum Phase: Equatable {
        case editing
        case saving
        case saved
        case failed(String)
    }

    // MARK: - Identity (fixed) + editable draft

    let reviewID: String
    /// Spot name for the read-only LOCATION header (falls back when the backend
    /// omits it).
    let spotName: String
    var draft: ReviewDraft

    /// The draft as first seeded from the review — the baseline for `hasChanges`.
    private let originalDraft: ReviewDraft

    private(set) var phase: Phase = .editing

    private let service: SpotService

    init(review: Review, service: SpotService = AppServices.spot) {
        reviewID = review.id
        spotName = review.spotName ?? "\(review.city), \(review.adminArea)"
        let seeded = ReviewDraft(from: review)
        draft = seeded
        originalDraft = seeded
        self.service = service
    }

    // MARK: - Derived

    var isSaving: Bool { phase == .saving }

    /// True once the user has edited any field — drives the "discard changes?"
    /// guard on dismiss.
    var hasChanges: Bool { draft != originalDraft }

    /// A valid rating is the only hard requirement to save (existing reviews always
    /// have a name/spot/photos; the edit endpoint touches content only).
    var canSave: Bool { (1...5).contains(draft.rating) }

    /// One-line reason the Save button is disabled, or nil when ready.
    var saveHint: String? { canSave ? nil : "Add a rating to save." }

    // MARK: - Save

    /// PATCHes the draft onto the existing review. Returns the updated `Review` on
    /// success (for the caller to swap into the list) or nil on failure/invalid.
    @discardableResult
    func save() async -> Review? {
        guard canSave else { return nil }
        phase = .saving
        do {
            let payload = CreateReviewViewModel.payload(from: draft, name: spotName,
                                                        lat: 0, lng: 0, photos: [])
            let updated = try await service.updateReview(reviewID: reviewID, payload: payload)
            phase = .saved
            return updated
        } catch {
            phase = .failed(error.localizedDescription)
            return nil
        }
    }
}
