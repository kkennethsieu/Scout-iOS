import SwiftUI

/// A review the signed-in user left, shown in the Profile "Reviews" tab. Renders
/// a full-bleed photo carousel (when the review has photos), the spot name, the
/// date, the user's star rating, and a notes excerpt. Degrades gracefully: a
/// review with no photos/notes collapses to just name + date.
struct ProfileReviewCard: View {
    let review: Review
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            if !review.photoUrls.isEmpty {
                // cornerRadius 0 — the card's clipShape rounds the top corners.
                PhotoCarousel(photos: review.photoUrls, height: 200, cornerRadius: 0)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Text(review.spotName ?? "Spot")
                        .font(.sHeadingM)
                        .foregroundStyle(Color.sTextPrimary)
                        .lineLimit(1)

                    Spacer(minLength: Spacing.sm)

                    optionsMenu
                }

                Text(dateText)
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextSecondary)

                if review.overallRating > 0 {
                    ratingRow
                }

                notes
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
        }
        .background(Color.sSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Options menu

    private var optionsMenu: some View {
        Menu {
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.sTextSecondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Review options")
    }

    // MARK: - Rating

    private var ratingRow: some View {
        HStack(spacing: Spacing.sm) {
            SStarRating(rating: .constant(review.overallRating), size: 14, tint: .sWarning, isInteractive: false)
            Text("\(review.overallRating)")
                .font(.sHeadingS)
                .foregroundStyle(Color.sTextPrimary)
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notes: some View {
        if let notes = review.notes, !notes.isEmpty {
            Text(notes)
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Stubbed for now — opens the full review once wired.
            Button {} label: {
                Text("See more")
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Date

    /// Recent reviews read relatively ("yesterday"); older ones show an absolute
    /// date ("Oct 24, 2023").
    private var dateText: String {
        let days = Calendar.current.dateComponents([.day], from: review.createdAt, to: .now).day ?? 0
        if days < 7 {
            return review.createdAt.formatted(.relative(presentation: .named))
        }
        return review.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Preview

#Preview("Profile Review Card") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            ForEach(Review.samples) { review in
                ProfileReviewCard(review: review)
            }
        }
        .padding(Spacing.lg)
    }
    .background(Color.sBackground)
}
