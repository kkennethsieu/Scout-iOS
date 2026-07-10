import SwiftUI

/// A clearable pill on the Explore feed showing the place the feed is scoped to
/// (picked in Search). Tapping anywhere on the chip resets to the default feed —
/// the whole pill is the tap target (the × just signals the action), so it's
/// reliably hittable rather than a lone ~12pt glyph.
struct ExplorePlaceChip: View {
    let name: String
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "mappin")
                    .font(.system(size: 13, weight: .semibold))

                Text(name)
                    .font(.sHeadingS)
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color.sAccent)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(Color.sAccentSoft)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear \(name) place filter")
        .accessibilityHint("Shows the default feed")
    }
}

// MARK: - Preview

#Preview("Place Chip") {
    ExplorePlaceChip(name: "Yosemite National Park") {}
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.sBackground)
}
