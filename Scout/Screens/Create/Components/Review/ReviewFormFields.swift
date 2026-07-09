import SwiftUI

/// The shared review-content fields — rating, notes, composition, gear, best
/// time/season, access level, and the access-logistics card — bound to a
/// `ReviewDraft`. Extracted so both the create flow (`WriteReviewScreen`) and the
/// edit flow (`EditReviewScreen`) render an identical form; only the surrounding
/// chrome (photos / location / submit bar) differs.
struct ReviewFormFields: View {
    @Binding var draft: ReviewDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            RateExperienceField(rating: $draft.rating)

            SSection(title: "Review Notes") {
                STextArea(
                    text: $draft.notes,
                    placeholder: "Share your experience, tips for other photographers, or gear recommendations…",
                    minHeight: 140
                )
            }

            SSection(title: "Composition Hint") {
                STextArea(
                    text: $draft.compositionHint,
                    placeholder: "e.g., Best from low angle near the rocks"
                )
            }

            SSection(title: "Gear Recommendation") {
                STextArea(
                    text: $draft.gear,
                    placeholder: "e.g., Wide preferred / Telephoto for compression"
                )
            }

            SMultiChipGroup(
                title: "Best time of day",
                options: CreateReviewViewModel.timeOptions,
                selection: $draft.times,
                titleFont: .sHeadingL
            ) { $0.label }

            SMultiChipGroup(
                title: "Best season",
                options: CreateReviewViewModel.seasonOptions,
                selection: $draft.seasons,
                titleFont: .sHeadingL
            ) { $0.label }

            SSingleChipGroup(
                title: "Access Level",
                options: CreateReviewViewModel.accessOptions,
                selection: $draft.accessLevel,
                titleFont: .sHeadingL,
            ) { $0 }

            AccessLogisticsCard(
                permitRequired: $draft.permitRequired,
                droneAllowed: $draft.droneAllowed,
                tripodAllowed: $draft.tripodAllowed,
                entranceFee: $draft.entranceFee,
                crowdLevel: $draft.crowdLevel
            )
        }
    }
}
