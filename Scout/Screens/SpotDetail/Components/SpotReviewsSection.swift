import SwiftUI

/// "Reviews" — header with count and a "View All" link, followed by a short
/// preview (first 3) of the loaded review cards. "View All" pushes the full,
/// searchable `ViewAllReviewsScreen`, sharing the same view model so its
/// already-loaded reviews appear instantly and paginate on scroll.
struct SpotReviewsSection: View {
    let spotName: String
    let viewModel: SpotDetailViewModel

    /// Show "View All" only when there's more than the preview reveals.
    private var showsViewAll: Bool {
        viewModel.reviews.count > 10 || viewModel.hasMore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reviews")
                        .font(.sHeadingL)
                        .foregroundStyle(Color.sTextPrimary)
                    Text(viewModel.reviewCountText)
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                }

                Spacer()

                if showsViewAll {
                    NavigationLink {
                        ViewAllReviewsScreen(spotName: spotName, viewModel: viewModel)
                    } label: {
                        Text("View All")
                            .font(.sBody)
                            .foregroundStyle(Color.sAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(viewModel.reviews) { review in
                ReviewCard(review: review)
            }
        }
    }
}
