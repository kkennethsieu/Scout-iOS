import SwiftUI

/// Loading placeholder for `SpotDetailScreen`. Mirrors the real content's layout —
/// hero, title, quick-facts grid, a couple of sections, and a review card — so the
/// structure is visible immediately. Shimmers (Reduce-Motion aware) and is inert.
struct SpotDetailSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Hero — full-bleed, bleeds under the status bar like SpotDetailHero.
                SkeletonBox(height: 320, cornerRadius: 0)

                VStack(alignment: .leading, spacing: Spacing.xl) {
                    titleBlock
                    quickFacts
                    section(lines: 2)
                    section(lines: 3)
                    reviewCard
                }
                .padding(.horizontal, Spacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 96)
        }
        .ignoresSafeArea(edges: .top)
        .shimmering()
        .allowsHitTesting(false)
    }

    // MARK: - Sections

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonBox(height: 30, width: 220, cornerRadius: Radius.sm)
            SkeletonBox(height: 18, width: 160, cornerRadius: Radius.sm)
        }
    }

    private var quickFacts: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SkeletonBox(height: 20, width: 120)
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonBox(height: 64, cornerRadius: Radius.md)
                }
            }
        }
    }   

    private func section(lines: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SkeletonBox(height: 20, width: 140)
            ForEach(0..<lines, id: \.self) { index in
                SkeletonBox(height: 14, width: index == lines - 1 ? 200 : nil)
            }
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SkeletonBox(height: 22, width: 110)
            SkeletonBox(height: 140, cornerRadius: Radius.lg)
        }
    }
}

// MARK: - Preview

#Preview("Spot Detail Skeleton") {
    SpotDetailSkeleton()
        .background(Color.sBackground)
}
