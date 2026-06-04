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

                    PhotoPickerField(
                        photos: viewModel.photos,
                        maxPhotos: CreateReviewViewModel.maxPhotos,
                        onAdd: { viewModel.addPhoto($0) },
                        onRemove: { viewModel.removePhoto(at: $0) }
                    )

                    STipBanner(message: "**Tip:** High-resolution shots with natural lighting showcase spots best.")

                    rateSection

                    SSection(title: "Review Notes (Required)") {
                        STextArea(
                            text: $viewModel.notes,
                            placeholder: "Share your experience, tips for other photographers, or gear recommendations…",
                            minHeight: 140
                        )
                    }

                    SSection(title: "Composition Hint (Optional)") {
                        STextArea(
                            text: $viewModel.compositionHint,
                            placeholder: "e.g., Best from low angle near the rocks"
                        )
                    }

                    SSection(title: "Gear Recommendation (Optional)") {
                        STextArea(
                            text: $viewModel.gear,
                            placeholder: "e.g., Wide preferred / Telephoto for compression"
                        )
                    }

                    SMultiChipGroup(
                        title: "Best time of day (Optional)",
                        options: CreateReviewViewModel.timeOptions,
                        selection: $viewModel.times,
                        titleFont: .sHeadingL
                    ) { $0.label }

                    SMultiChipGroup(
                        title: "Environment (Optional)",
                        options: CreateReviewViewModel.environmentOptions,
                        selection: $viewModel.environments,
                        titleFont: .sHeadingL
                    ) { $0 }

                    SSingleChipGroup(
                        title: "Access Level (Required)",
                        options: CreateReviewViewModel.accessOptions,
                        selection: $viewModel.accessLevel,
                        titleFont: .sHeadingL
                    ) { $0 }

                    AccessLogisticsCard(
                        permitRequired: $viewModel.permitRequired,
                        droneAllowed: $viewModel.droneAllowed,
                        tripodAllowed: $viewModel.tripodAllowed,
                        entranceFee: $viewModel.entranceFee,
                        crowdLevel: $viewModel.crowdLevel
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }

            footer
        }
        .background(Color.sBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Rating

    private var rateSection: some View {
        VStack(spacing: Spacing.md) {
            Text("Rate your experience")
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)
            SStarRating(rating: $viewModel.rating, size: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            SPrimaryButton(title: "Submit Review", isLoading: viewModel.isSubmitting) {
                Task {
                    await viewModel.submit()
                    if viewModel.phase == .success { onComplete() }
                }
            }
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .background(.ultraThinMaterial)
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
