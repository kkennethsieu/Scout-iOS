import SwiftUI

/// Loading placeholder for the search results list. Renders a shimmering column of
/// row stand-ins mirroring `SpotResultRow`/`PlaceResultRow` (leading tile + title +
/// subtitle), so the list's structure shows while the backend search runs.
/// Reduce-Motion aware and inert.
struct SearchSkeleton: View {
    var rowCount = 6

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(0..<rowCount, id: \.self) { _ in
                row
            }
        }
        .padding(.top, Spacing.sm)
        .shimmering()
        .allowsHitTesting(false)
    }

    private var row: some View {
        HStack(spacing: Spacing.md) {
            SkeletonBox(height: 44, width: 44, cornerRadius: Radius.md)   // icon tile

            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonBox(height: 16, width: 180)   // title
                SkeletonBox(height: 13, width: 120)   // subtitle
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Preview

#Preview("Search Skeleton") {
    ScrollView {
        SearchSkeleton()
            .padding(.horizontal, Spacing.lg)
    }
    .background(Color.sBackground)
}
