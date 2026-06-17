import SwiftUI

/// "Reviews" — header with count, followed by the review cards.
struct SpotReviewsSection: View {
    let reviews: [Review]
    let countText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reviews")
                    .font(.sHeadingL)
                    .foregroundStyle(Color.sTextPrimary)
                Text(countText)
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextSecondary)
            }

            ForEach(reviews) { review in
                ReviewCard(review: review)
            }
        }
    }
}
