import SwiftUI

/// Compact card shown at the bottom of the Map tab when a pin is selected.
/// Thumbnail + name + rating + locality; the whole card navigates to detail.
struct MapSpotPreview: View {
    let spot: SpotSummary
    var distance: String?

    var body: some View {
        HStack(spacing: Spacing.md) {
            thumbnail

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(spot.name)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sWarning)
                    Text(spot.avgRating.formatted(.number.precision(.fractionLength(1))))
                        .font(.sHeadingS)
                        .foregroundStyle(Color.sTextPrimary)
                    Text("(\(spot.reviewCount))")
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.sTextTertiary)
        }
        .padding(Spacing.md)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(Color.sSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.sBorderSubtle, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private var subtitle: String? {
        let place = [spot.city, spot.adminArea]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return [distance, place.isEmpty ? nil : place]
            .compactMap { $0 }
            .joined(separator: " • ")
    }

    private var thumbnail: some View {
        Color.sBorderSubtle
            .frame(width: 64, height: 64)
            .overlay {
                if let url = spot.coverPhoto {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.sBorderSubtle
                    }
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(Color.sTextTertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

// MARK: - Preview

#Preview("Map Spot Preview") {
    ZStack {
        Color.sBackground.ignoresSafeArea()
        MapSpotPreview(spot: .sample(name: "Hollywood Sign Trail"), distance: "4.2 mi")
            .padding(Spacing.lg)
    }
}
