import SwiftUI

/// "Reviews" — header with count + "View all", followed by the review cards.
struct SpotReviewsSection: View {
    let reviews: [Review]
    let countText: String
    var onViewAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reviews")
                        .font(.sHeadingL)
                        .foregroundStyle(Color.sTextPrimary)
                    Text(countText)
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                }
                Spacer()
                Button(action: onViewAll) {
                    Text("View all")
                        .font(.sHeadingS)
                        .foregroundStyle(Color.sAccent)
                }
            }

            ForEach(reviews) { review in
                ReviewCard(review: review)
            }
        }
    }
}
