import Foundation

/// The editable content of a review-in-progress — the UI-shaped draft the create
/// form binds to.
///
/// Deliberately distinct from the `Review` response model: it uses selection sets
/// and non-optional strings (what SwiftUI fields bind to directly), holds no
/// server-generated identity (`id`/`user_id`/URLs), and is freely mutable.
/// `CreateReviewViewModel` owns one and maps it onto the submission payload at
/// submit time. Spot identity (name / coordinate / photos) lives on the VM, not
/// here — this is review content only.
struct ReviewDraft: Equatable {
    var rating: Int = 0
    var notes: String = ""
    var compositionHint: String = ""
    var gear: String = ""
    var times: Set<TimeOfDay> = []
    var seasons: Set<Season> = []
    // Optional vocabularies: nil = "unanswered" (distinct from any chosen value).
    var accessLevel: String? = nil
    var crowdLevel: String? = nil
    // Tristate: nil = "unanswered" (distinct from false), the default.
    var permitRequired: Bool? = nil
    var droneAllowed: Bool? = nil
    var tripodAllowed: Bool? = nil
    // Numeric amount as entered text ("" = unanswered). Parsed to `Double?` at the
    // payload seam; backend `entrance_fee` is `Optional[float]` (≥ 0).
    var entranceFee: String = ""

    init() {}

    /// Seeds the form from an existing review, for the edit flow. Inverse of the
    /// draft → payload mapping: optional strings collapse to "", the raw
    /// time/season lists become selection sets, and the fee renders back to text.
    init(from review: Review) {
        rating = review.overallRating
        notes = review.notes ?? ""
        compositionHint = review.compositionHints ?? ""
        gear = review.gearRecommendations ?? ""
        times = Set(review.times)
        seasons = Set(review.seasons)
        accessLevel = review.accessLevel
        crowdLevel = review.crowdLevel
        permitRequired = review.permitRequired
        droneAllowed = review.droneAllowed
        tripodAllowed = review.tripodAllowed
        entranceFee = review.entranceFee.map { $0.formatted(.number.grouping(.never)) } ?? ""
    }
}
