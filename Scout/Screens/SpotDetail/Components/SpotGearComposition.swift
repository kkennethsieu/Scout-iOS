import SwiftUI

/// "Gear & Composition" — stacked callout blocks listing aggregated gear
/// recommendations and composition hints. Renders nothing when both are empty.
struct SpotGearComposition: View {
    let gearRecommendations: [String]
    let compositionHints: [String]

    var body: some View {
        if !gearRecommendations.isEmpty || !compositionHints.isEmpty {
            SSection(title: "Gear & Composition") {
                VStack(spacing: Spacing.md) {
                    if !gearRecommendations.isEmpty {
                        calloutBlock(icon: "camera.aperture",
                                     title: "Gear Recommendations",
                                     entries: gearRecommendations)
                    }
                    if !compositionHints.isEmpty {
                        calloutBlock(icon: "square.grid.2x2",
                                     title: "Composition Hints",
                                     entries: compositionHints)
                    }
                }
            }
        }
    }

    private func calloutBlock(icon: String, title: String, entries: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sTextPrimary)
                Text(title)
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
            }
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                Text(entry)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
    }
}
