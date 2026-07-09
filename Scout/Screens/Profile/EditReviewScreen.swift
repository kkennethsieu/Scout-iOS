import SwiftUI

/// Edit-an-existing-review form, presented as a sheet from the Profile "Reviews"
/// tab. Reuses the shared `ReviewFormFields` (so it matches the create form) with
/// a read-only location header and a "Save Changes" bar; photos aren't shown
/// because the update endpoint can't change them. On success it hands the updated
/// review back via `onSaved` and dismisses.
struct EditReviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditReviewViewModel
    @State private var showError = false
    /// Drives the "discard changes?" guard shown when closing with unsaved edits.
    @State private var showDiscardWarning = false

    /// Called with the updated review on a successful save, so the list can swap
    /// the card in place without a refetch.
    private let onSaved: (Review) -> Void

    init(review: Review, onSaved: @escaping (Review) -> Void) {
        _viewModel = State(initialValue: EditReviewViewModel(review: review))
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    SSheetHeader(title: "Edit Review") { attemptClose() }

                    // No "Change location" — the spot is fixed when editing.
                    ReviewLocationHeader(spotName: viewModel.spotName)

                    ReviewFormFields(draft: $viewModel.draft)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }

            ReviewSubmitBar(
                title: "Save Changes",
                isSubmitting: viewModel.isSaving,
                isEnabled: viewModel.canSave,
                hint: viewModel.saveHint
            ) {
                Task {
                    if let updated = await viewModel.save() {
                        onSaved(updated)
                        dismiss()
                    } else if case .failed = viewModel.phase {
                        showError = true
                    }
                }
            }
        }
        .background(Color.sBackground)
        // Block swipe-to-dismiss while there are unsaved edits, so the discard
        // guard (via the X) is the only way out — no accidental data loss.
        .interactiveDismissDisabled(viewModel.hasChanges)
        .alert("Couldn't save changes", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if case .failed(let message) = viewModel.phase {
                Text(message)
            }
        }
        .sConfirmationDialog(isPresented: $showDiscardWarning) {
            SConfirmationDialog(
                title: "Discard changes?",
                message: "Going back will discard your changes.",
                primaryTitle: "Discard Changes",
                isDestructive: true,
                primaryAction: { showDiscardWarning = false; dismiss() },
                secondaryTitle: "Keep Editing",
                secondaryAction: { showDiscardWarning = false }
            )
        }
    }

    /// Closes immediately when nothing changed; otherwise warns first.
    private func attemptClose() {
        if viewModel.hasChanges {
            showDiscardWarning = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Edit Review") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            EditReviewScreen(review: Review.samples[0]) { _ in }
        }
}
