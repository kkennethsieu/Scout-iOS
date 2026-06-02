import SwiftUI

/// A single tappable row in the "Nearby spots" sheet: a square thumbnail, the
/// spot name, a distance + category line, and a trailing chevron. Rendered as a
/// flat list row (callers add `Divider`s between them), not a bordered card.
struct NearbySpotRow: View {
    let spot: NearbySpot
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                thumbnail

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(spot.name)
                        .font(.sHeadingM)
                        .foregroundStyle(Color.sTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.sm) {
                        Text(spot.distance)
                            .font(.sBodyS)
                            .foregroundStyle(Color.sTextSecondary)

                        STag(text: spot.category)
                    }
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sTextTertiary)
            }
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(spot.name), \(spot.distance), \(spot.category)")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Pieces

    private var thumbnail: some View {
        // Size from a flexible Color, overlay the image — same pattern as
        // `SpotCard` so a loaded photo can't stretch the row.
        Color.sBorderSubtle
            .overlay {
                AsyncImage(url: spot.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var placeholder: some View {
        ZStack {
            Color.sAccentSoft
            Image(systemName: "photo")
                .font(.system(size: 18))
                .foregroundStyle(Color.sTextTertiary)
        }
    }

}

// MARK: - Preview

#Preview("Nearby Spot Row") {
    VStack(spacing: 0) {
        ForEach(NearbySpot.samples) { spot in
            NearbySpotRow(spot: spot)
            Divider().background(Color.sBorderSubtle)
        }
    }
    .padding(.horizontal, Spacing.lg)
    .background(Color.sBackground)
}
