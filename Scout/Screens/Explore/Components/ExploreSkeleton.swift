import SwiftUI

/// Loading placeholder for the Explore feed. Renders a shimmering list of card
/// stand-ins mirroring `SpotCard` (cover + name/rating + subtitle), so the feed's
/// structure shows immediately. Reduce-Motion aware and inert. Lives inside
/// `ExploreScreen`'s ScrollView, which supplies the horizontal padding.
struct ExploreSkeleton: View {
    var cardCount = 5

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ForEach(0..<cardCount, id: \.self) { _ in
                card
            }
        }
        .padding(.top, Spacing.xs)
        .shimmering()
        .allowsHitTesting(false)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Cover — matches PhotoCarousel's default 220 height + Radius.lg.
            SkeletonBox(height: 220, cornerRadius: Radius.lg)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    SkeletonBox(height: 18, width: 160)   // name
                    Spacer()
                    SkeletonBox(height: 16, width: 56)    // rating
                }
                SkeletonBox(height: 14, width: 200)       // subtitle
            }
        }
    }
}

// MARK: - Preview

#Preview("Explore Skeleton") {
    ScrollView {
        ExploreSkeleton()
            .padding(.horizontal, Spacing.lg)
    }
    .background(Color.sBackground)
}
