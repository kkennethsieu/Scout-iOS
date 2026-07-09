import SwiftUI

/// The Reviews tab of the Profile screen: load / error / empty states, the
/// paginated list of the user's reviews, and the per-review delete confirmation.
/// Pulled out of `ProfileScreen` so the screen body stays focused on layout and
/// navigation; the "which review is pending deletion" state lives here, next to
/// the list that drives it.
struct ProfileReviewsList: View {
    let viewModel: ProfileViewModel
    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    /// The review the user tapped "Delete" on; drives the confirmation dialog.
    @State private var reviewPendingDeletion: Review?
    /// The review the user tapped "Edit" on; drives the edit sheet.
    @State private var reviewToEdit: Review?

    var body: some View {
        content
            .sheet(item: $reviewToEdit) { review in
                EditReviewScreen(review: review) { updated in
                    viewModel.applyUpdatedReview(updated)
                    toasts?.show("Review updated")
                }
            }
            .confirmationDialog(
                "Delete this review?",
                isPresented: Binding(
                    get: { reviewPendingDeletion != nil },
                    set: { if !$0 { reviewPendingDeletion = nil } }
                ),
                titleVisibility: .visible,
                presenting: reviewPendingDeletion
            ) { review in
                Button("Delete", role: .destructive) {
                    Task {
                        if await viewModel.deleteReview(review) {
                            toasts?.show("Review deleted")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { review in
                Text("This permanently removes your review\(review.spotName.map { " of \($0)" } ?? "").")
            }
            .alert(
                "Couldn't delete review",
                isPresented: Binding(
                    get: { viewModel.deleteError != nil },
                    set: { if !$0 { viewModel.dismissDeleteError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.deleteError ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            SLoadingState()
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        case .loaded:
            if viewModel.reviews.isEmpty {
                SEmptyStateView(icon: "star", title: "No reviews yet")
                    .padding(.vertical, Spacing.xxl)
            } else {
                list
            }
        }
    }

    private var list: some View {
        // Lazy so off-screen cards aren't realized up front — otherwise the last
        // card's `.onAppear` fires immediately (and again after each appended
        // page), cascading several `loadMore()` calls without any scrolling.
        LazyVStack(spacing: Spacing.lg) {
            ForEach(viewModel.reviews) { review in
                ProfileReviewCard(
                    review: review,
                    isDeleting: viewModel.deletingReviewID == review.id,
                    onEdit: { reviewToEdit = review },
                    onDelete: { reviewPendingDeletion = review }
                )
                .onAppear {
                    // Reached the last card — pull the next page.
                    if review.id == viewModel.reviews.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .tint(Color.sAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
        }
        .padding(.bottom, Spacing.xxxl)
    }
}
