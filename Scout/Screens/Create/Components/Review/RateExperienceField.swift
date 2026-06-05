import SwiftUI

/// The "Rate your experience" field in the review form: a required-tagged label
/// over a 1–5 star picker. Rating is the one required content field (alongside a
/// photo), so it carries a "Required" `SBadge`.
struct RateExperienceField: View {
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Text("Rate your experience")
                    .font(.sHeadingL)
                    .foregroundStyle(Color.sTextPrimary)
                SBadge("Required")
            }
            SStarRating(rating: $rating, size: 30)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview("Rate Experience") {
    struct Demo: View {
        @State private var rating = 0
        var body: some View {
            RateExperienceField(rating: $rating)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.sBackground)
        }
    }
    return Demo()
}
