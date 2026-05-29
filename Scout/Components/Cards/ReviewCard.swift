import SwiftUI

/// A single review on the Spot Detail page: author header, notes, photo grid,
/// and a like/comment footer.
struct ReviewCard: View {
    let review: Review
    var authorName: String = "Marcus Thorne"
    var avatarURL: URL? = nil
    var likeCount: Int = 24
    var commentCount: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            notes
            if !review.photoUrls.isEmpty { photoGrid }
            footer
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.sSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.md) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(authorName)
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
                Text(review.createdAt, format: .relative(presentation: .named))
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextSecondary)
            }

            Spacer()

            stars
        }
    }

    private var avatar: some View {
        Group {
            if let avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.sBorderSubtle
                }
            } else {
                Circle()
                    .fill(Color.sAccentSoft)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.sTextTertiary)
                    }
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }

    private var stars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= review.overallRating ? "star.fill" : "star")
                    .font(.system(size: 13))
                    .foregroundStyle(index <= review.overallRating ? Color.sWarning : Color.sRatingEmpty)
            }
        }
    }

    // MARK: - Notes

    private var notes: some View {
        Text(review.notes)
            .font(.sBodyL)
            .foregroundStyle(Color.sTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Photo grid

    private var photoGrid: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(review.photoUrls.prefix(2).enumerated()), id: \.offset) { _, url in
                // Size each tile from a flexible Color and overlay the image, so
                // a loaded photo's native width can't drive the row wider than
                // the available space.
                Color.sBorderSubtle
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .overlay {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.sBorderSubtle
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Spacing.xl) {
            Label("\(likeCount)", systemImage: "hand.thumbsup")
            Label("\(commentCount)", systemImage: "bubble.left")
        }
        .font(.sBody)
        .foregroundStyle(Color.sTextSecondary)
    }
}

// MARK: - Preview

#Preview("Review Card") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            ForEach(Review.samples) { review in
                ReviewCard(review: review)
            }
        }
        .padding(Spacing.lg)
    }
    .background(Color.sBackground)
}
