import SwiftUI

/// Large featured spot card for the Explore feed: a swipeable cover-photo
/// carousel with a bookmark button overlaid top-right, then name + rating and a
/// metadata subtitle below.
struct SpotCard: View {
    let spot: SpotSummary
    /// Placeholder distance string (e.g. "0.4 miles away") until real location
    /// distance is wired.
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
        carousel
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(alignment: .topTrailing) {
                saveButton
                    .padding(Spacing.md)
            }
            .overlay(alignment: .bottom) {
                if photos.count > 1 {
                    pageDots
                        .padding(.bottom, Spacing.md)
                }
            }
    }

    @ViewBuilder
    private var carousel: some View {
        if photos.isEmpty {
            photoPlaceholder
        } else if photos.count == 1 {
            asyncPhoto(photos[0])
        } else {
            TabView(selection: $page) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                    asyncPhoto(url).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private func asyncPhoto(_ url: URL) -> some View {
        // Size from a flexible Color and overlay the image, so a loaded photo's
        // native dimensions can't drive the card wider than its container.
        Color.sBorderSubtle
            .overlay {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        photoPlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        photoPlaceholder
                    }
                }
            }
            .clipped()
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.sAccentSoft
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(Color.sTextTertiary)
        }
    }

    private var pageDots: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(photos.indices, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index == page ? 1 : 0.5))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(.black.opacity(0.25), in: Capsule())
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
