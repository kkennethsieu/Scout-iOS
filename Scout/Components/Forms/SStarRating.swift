import SwiftUI

/// Interactive 1–5 star rating. Tapping a star sets the rating; pass
/// `isInteractive: false` for a read-only display. Tinted with `sAccent` to
/// match the review form (distinct from the gold rating *readouts* on cards).
struct SStarRating: View {
    @Binding var rating: Int
    var maximum: Int = 5
    var size: CGFloat = 28
    var tint: Color = .sAccent
    var isInteractive: Bool = true

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(1...maximum, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? tint : Color.sRatingEmpty)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isInteractive else { return }
                        rating = index
                    }
                    .accessibilityLabel("\(index) star\(index == 1 ? "" : "s")")
                    .accessibilityAddTraits(index == rating ? [.isButton, .isSelected] : .isButton)
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
    }
}

// MARK: - Preview

#Preview("Star Rating") {
    struct Demo: View {
        @State private var rating = 3
        var body: some View {
            VStack(spacing: Spacing.xl) {
                SStarRating(rating: $rating, size: 30)
                SStarRating(rating: .constant(5), size: 18, isInteractive: false)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Demo()
}
