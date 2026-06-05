import SwiftUI
import CoreLocation

/// Full review form, the last step of the create flow. Composes the shared form
/// kit (`SSection`, `SMultiChipGroup`, `STextArea`, `SStarRating`, …) plus a few
/// local pieces (`ReviewLocationHeader`, `PhotoPickerField`). Backed by the flow's
/// `CreateReviewViewModel`. Pushed onto the flow's NavigationStack, so
/// back/"Change location" pops to the map; a successful submit calls `onComplete`
/// to tear down the whole flow.
struct WriteReviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateReviewViewModel
    /// Called after a successful submit so the flow can dismiss everything.
    var onComplete: () -> Void = {}

    init(viewModel: CreateReviewViewModel, onComplete: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    SSheetHeader(title: "Write Review") { dismiss() }

                    ReviewLocationHeader(spotName: viewModel.spotName) { dismiss() }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            Text("Photos")
                                .font(.sHeadingL)
                                .foregroundStyle(Color.sTextPrimary)
                            SBadge("Required")
                        }
                        PhotoPickerField(
                            photos: viewModel.photos,
                            maxPhotos: CreateReviewViewModel.maxPhotos,
                            onAdd: { viewModel.addPhoto($0) },
                            onRemove: { viewModel.removePhoto(at: $0) }
                        )
                    }

                    STipBanner(message: "**Tip:** High-resolution shots with natural lighting showcase spots best.")

                    RateExperienceField(rating: $viewModel.draft.rating)

                    SSection(title: "Review Notes") {
                        STextArea(
                            text: $viewModel.draft.notes,
                            placeholder: "Share your experience, tips for other photographers, or gear recommendations…",
                            minHeight: 140
                        )
                    }

                    SSection(title: "Composition Hint") {
                        STextArea(
                            text: $viewModel.draft.compositionHint,
                            placeholder: "e.g., Best from low angle near the rocks"
                        )
                    }

                    SSection(title: "Gear Recommendation") {
                        STextArea(
                            text: $viewModel.draft.gear,
                            placeholder: "e.g., Wide preferred / Telephoto for compression"
                        )
                    }

                    SMultiChipGroup(
                        title: "Best time of day",
                        options: CreateReviewViewModel.timeOptions,
                        selection: $viewModel.draft.times,
                        titleFont: .sHeadingL
                    ) { $0.label }

                    SMultiChipGroup(
                        title: "Best season",
                        options: CreateReviewViewModel.seasonOptions,
                        selection: $viewModel.draft.seasons,
                        titleFont: .sHeadingL
                    ) { $0.label }

                    SSingleChipGroup(
                        title: "Access Level",
                        options: CreateReviewViewModel.accessOptions,
                        selection: $viewModel.draft.accessLevel,
                        titleFont: .sHeadingL,
                    ) { $0 }

                    AccessLogisticsCard(
                        permitRequired: $viewModel.draft.permitRequired,
                        droneAllowed: $viewModel.draft.droneAllowed,
                        tripodAllowed: $viewModel.draft.tripodAllowed,
                        entranceFee: $viewModel.draft.entranceFee,
                        crowdLevel: $viewModel.draft.crowdLevel
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }

            ReviewSubmitBar(
                isSubmitting: viewModel.isSubmitting,
                isEnabled: viewModel.canSubmit,
                hint: viewModel.submitHint
            ) {
                Task {
                    await viewModel.submit()
                    if viewModel.phase == .success { onComplete() }
                }
            }
        }
        .background(Color.sBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Preview

private func previewViewModel() -> CreateReviewViewModel {
    CreateReviewViewModel(
        target: .newSpot(name: "The Emerald Basin"),
        coordinate: CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784),
        regionText: "Portland, USA"
    )
}

#Preview("Write Review") {
    WriteReviewScreen(viewModel: previewViewModel())
}

#Preview("Write Review — Dark") {
    WriteReviewScreen(viewModel: previewViewModel())
        .preferredColorScheme(.dark)
}
