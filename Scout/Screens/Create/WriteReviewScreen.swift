import SwiftUI

/// Full review form reached from a spot's "Leave a review" action (or the
/// create flow once a spot is chosen). Composes the shared form kit
/// (`SSection`, `SMultiChipGroup`, `STextArea`, `SStarRating`, …) plus a few
/// local pieces. Not wired — edits a local `ReviewDraft` and the submit/change
/// actions are stubs.
struct WriteReviewScreen: View {
    var spotName: String = "The Emerald Basin"

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ReviewDraft()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    SSheetHeader(title: "Write Review") { dismiss() }

                    locationBlock

                    PhotoUploadArea()

                    tipBanner

                    rateSection

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
                        options: ReviewDraft.timeOptions,
                        selection: $draft.times,
                        titleFont: .sHeadingL
                    ) { $0.label }

                    SMultiChipGroup(
                        title: "Environment",
                        options: ReviewDraft.environmentOptions,
                        selection: $draft.environments,
                        titleFont: .sHeadingL
                    ) { $0 }

                    accessLevelSection

                    AccessLogisticsCard(
                        permitRequired: $draft.permitRequired,
                        droneAllowed: $draft.droneAllowed,
                        tripodAllowed: $draft.tripodAllowed,
                        entranceFee: $draft.entranceFee,
                        crowdLevel: $draft.crowdLevel
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }

            footer
        }
        .background(Color.sBackground)
    }

    // MARK: - Location

    private var locationBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("LOCATION")
                .font(.sCaption)
                .foregroundStyle(Color.sTextTertiary)

            Text(spotName)
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)

            Button {
                // TODO: change-location flow
            } label: {
                Text("Change location")
                    .font(.sBody)
                    .foregroundStyle(Color.sAccent)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tip

    private var tipBanner: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "lightbulb")
                .font(.system(size: 14))
                .foregroundStyle(Color.sAccent)
            Text("**Tip:** High-resolution shots with natural lighting showcase spots best.")
                .font(.sBodyS)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(Color.sAccentSoft, in: RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Rating

    private var rateSection: some View {
        VStack(spacing: Spacing.md) {
            Text("Rate your experience")
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)
            SStarRating(rating: $draft.rating, size: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Access level (required single-select)

    private var accessLevelSection: some View {
        SSection(title: "Access Level", titleFont: .sHeadingL) {
            FlowLayout(spacing: Spacing.sm) {
                ForEach(ReviewDraft.accessOptions, id: \.self) { level in
                    SFilterChip(title: level, isSelected: draft.accessLevel == level) {
                        draft.accessLevel = level
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            SPrimaryButton(title: "Submit Review") {
                // TODO: submit review
                dismiss()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Draft model

/// Local editable state for the form. The submit counterpart to `Review`; at
/// wire-up it maps onto the `ReviewResponse` payload. Two reconciliations to
/// note then:
/// - `environments` is a `Set` here, but `Review.environment` is a single
///   `String` (the mockup allows multiple selections).
/// - these `environmentOptions` differ from `SpotFilters.environmentOptions`.
struct ReviewDraft {
    var rating: Int = 4
    var notes: String = ""
    var compositionHint: String = ""
    var gear: String = ""
    var times: Set<TimeOfDay> = [.goldenHour]
    var environments: Set<String> = ["Alpine", "Water"]
    var accessLevel: String = "Moderate"
    var permitRequired: Bool = false
    var droneAllowed: Bool = true
    var tripodAllowed: Bool = true
    var entranceFee: String = ""
    var crowdLevel: String = "Moderate"

    /// Ordered to match the mockup (not `TimeOfDay.allCases`).
    static let timeOptions: [TimeOfDay] = [.goldenHour, .blueHour, .sunrise, .night, .midday]
    static let environmentOptions = ["Forest", "Alpine", "Water", "Panoramic", "Coast"]
    static let accessOptions = ["Easy", "Moderate", "Hard"]
}

// MARK: - Preview

#Preview("Write Review") {
    WriteReviewScreen()
}

#Preview("Write Review — Dark") {
    WriteReviewScreen()
        .preferredColorScheme(.dark)
}
