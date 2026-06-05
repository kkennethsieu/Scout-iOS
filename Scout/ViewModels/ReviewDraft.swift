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
struct ReviewDraft {
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
    // Free-text amount for now; "" is a natural empty. (Backend `entrance_fee` is
    // actually an enum vocabulary — this field gets reworked when submission is wired.)
    var entranceFee: String = ""
}
