import SwiftUI

/// A clearable pill on the Explore feed showing the place the feed is scoped to
/// (picked in Search). Tapping the × resets to the default feed.
struct ExplorePlaceChip: View {
    let name: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "mappin")
                .font(.system(size: 13, weight: .semibold))

            Text(name)
                .font(.sHeadingS)
                .lineLimit(1)

            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear place filter")
        }
        .foregroundStyle(Color.sAccent)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule().fill(Color.sAccentSoft)
        )
    }
}

// MARK: - Preview

#Preview("Place Chip") {
    ExplorePlaceChip(name: "Yosemite National Park") {}
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.sBackground)
}
