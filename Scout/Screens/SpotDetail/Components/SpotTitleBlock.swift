import SwiftUI

/// The spot's name plus a single metadata line: locality · ★ rating (reviewCount).
struct SpotTitleBlock: View {
    let name: String
    let subtitle: String
    let rating: Double
    let reviewCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(name)
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)

            HStack(spacing: Spacing.sm) {
                Text(subtitle)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)

                separator

                ratingCluster
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var separator: some View {
        Text("·")
            .font(.sBody)
            .foregroundStyle(Color.sTextTertiary)
    }

    private var ratingCluster: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(Color.sWarning)

            Text(String(format: "%.1f", rating))
                .font(.sBody.weight(.semibold))
                .foregroundStyle(Color.sTextPrimary)

            Text("(\(reviewCount))")
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rated \(String(format: "%.1f", rating)) from \(reviewCount) reviews")
    }
}

// MARK: - Preview

#Preview("Spot Title Block") {
    SpotTitleBlock(
        name: "Cedar Cathedral",
        subtitle: "Cascade Range, WA",
        rating: 4.9,
        reviewCount: 128
    )
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.sBackground)
}
