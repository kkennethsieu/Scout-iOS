import SwiftUI
import CoreLocation

/// Full review form, the last step of the create flow. Composes the shared form
/// kit (`SSection`, `SMultiChipGroup`, `STextArea`, `SStarRating`, …) plus a few
/// local pieces (`ReviewLocationHeader`, `PhotoPickerField`). Backed by the flow's
/// `CreateReviewViewModel`. Pushed onto the flow's NavigationStack, so
/// back/"Change location" pops to the map. A successful submit flips
/// `viewModel.phase` to `.success`; the flow container observes that and swaps in
/// the success screen, so this view only needs to surface a failure.
struct WriteReviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateReviewViewModel
    @State private var showError = false
    /// The active confirmation prompt, derived from the view model's submit phase
    /// (see `.onChange` below). Driving it from `phase` — rather than only from the
    /// submit-button tap — means a prompt triggered *by another prompt's action*
    /// (e.g. "Add my review" → the spot exists → "you already reviewed it")
    /// appears immediately, with no second Submit tap.
    @State private var prompt: ActivePrompt?

    /// The two mutually-exclusive create-flow confirmations, both rendered with the
    /// shared `SConfirmationDialog`.
    private enum ActivePrompt {
        case duplicateSpot(CreateReviewViewModel.DuplicateSpot)
        case alreadyReviewed(reviewID: String)
    }

    private var promptBinding: Binding<ActivePrompt?> {
        Binding(get: { prompt }, set: { prompt = $0 })
    }

    init(viewModel: CreateReviewViewModel) {
        _viewModel = State(initialValue: viewModel)
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

                    ReviewFormFields(draft: $viewModel.draft)
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
                // Presentation is driven centrally by `onChange(of: phase)` below,
                // so both the initial submit and any prompt-triggered follow-up
                // (e.g. "Add my review") surface their result without a re-tap.
                Task { await viewModel.submit() }
            }
        }
        .background(Color.sBackground)
        .toolbar(.hidden, for: .navigationBar)
        // Map every terminal submit phase to its prompt. Success is handled by the
        // flow container (`CreateFlowHost` observes `phase`), so it's not here.
        .onChange(of: viewModel.phase) { _, phase in
            switch phase {
            case .duplicate(let dup):       prompt = .duplicateSpot(dup)
            case .alreadyReviewed(let id):  prompt = .alreadyReviewed(reviewID: id)
            case .failed:                   prompt = nil; showError = true
            case .success:                  prompt = nil
            default:                        break
            }
        }
        .alert("Couldn't post your review", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if case .failed(let message) = viewModel.phase {
                Text(message)
            }
        }
        .sConfirmationDialog(item: promptBinding) { active in
            switch active {
            case .duplicateSpot(let dup):
                SConfirmationDialog(
                    title: "Spot already exists",
                    message: dup.message ?? "A spot already exists at this location.",
                    primaryTitle: "Add my review",
                    isPrimaryLoading: viewModel.isSubmitting,
                    primaryAction: { Task { await viewModel.addReviewToExistingSpot() } },
                    secondaryTitle: "Not now",
                    secondaryAction: { prompt = nil }
                )
            case .alreadyReviewed:
                SConfirmationDialog(
                    title: "You've already reviewed this spot",
                    message: "Would you like to replace your existing review with this one?",
                    primaryTitle: "Update Review",
                    isPrimaryLoading: viewModel.isSubmitting,
                    primaryAction: { Task { await viewModel.updateExistingReview() } },
                    secondaryTitle: "Cancel",
                    secondaryAction: { prompt = nil }
                )
            }
        }
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
