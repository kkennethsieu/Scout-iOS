import SwiftUI

/// Large featured spot card for the Explore feed: a swipeable cover-photo
/// carousel with a bookmark button overlaid top-right, then name + rating and a
/// metadata subtitle below.
struct SpotCard: View {
    let spot: SpotSummary

    var distance: String?
    var isSaved: Bool = false
    var onTapSave: () -> Void = {}

    @State private var page = 0

    private var photos: [URL] { spot.carouselPhotos }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            photo
            info
        }
    }

    // MARK: - Photo

    private var photo: some View {
        PhotoCarousel(photos: photos)
            .overlay(alignment: .topTrailing) {
                saveButton.padding(Spacing.md)
            }
    }

    private var saveButton: some View {
        Button(action: onTapSave) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isSaved)
    }

    // MARK: - Info

    private var info: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(spot.name)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)

                Spacer(minLength: Spacing.sm)

                ratingBadge
            }

            if let subtitle {
                Text(subtitle)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var ratingBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.sWarning)
            Text(spot.avgRating.formatted(.number.precision(.fractionLength(1))))
                .font(.sHeadingS)
                .foregroundStyle(Color.sTextPrimary)
            Text("(\(spot.reviewCount))")
                .font(.sBodyS)
                .foregroundStyle(Color.sTextSecondary)
        }
    }

    /// Distance + locality. Environment isn't part of `SpotSummaryResponse`, so
    /// the subtitle uses city/admin area as the secondary descriptor.
    private var subtitle: String? {
        let place = [spot.city, spot.adminArea]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return [distance, place.isEmpty ? nil : place]
            .compactMap { $0 }
            .joined(separator: " • ")
    }
}

// MARK: - Preview

#Preview("Spot Card") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            SpotCard(spot: .sample(name: "Cedar Cathedral", rating: 4.9),
                     distance: "0.4 miles away")
            SpotCard(spot: .sample(name: "Mirror Reservoir", rating: 4.7),
                     distance: "1.2 miles away",
                     isSaved: true)
        }
        .padding(Spacing.lg)
    }
    .background(Color.sBackground)
}
