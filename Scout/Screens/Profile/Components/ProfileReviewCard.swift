import SwiftUI

/// A review the signed-in user left, shown in the Profile "Reviews" tab. Renders
/// a full-bleed photo carousel (when the review has photos), the spot name, the
/// date, the user's star rating, and a notes excerpt. Degrades gracefully: a
/// review with no photos/notes collapses to just name + date.
struct ProfileReviewCard: View {
    let review: Review
    /// A delete is in flight for this review — dims the card and shows a spinner.
    var isDeleting: Bool = false
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    /// Notes collapse to this many lines; "See more" appears only when the full
    /// text exceeds it.
    private let notesLineLimit = 2
    @State private var fullNotesHeight: CGFloat = 0
    @State private var clampedNotesHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            if !review.photoUrls.isEmpty {
                // cornerRadius 0 — the card's clipShape rounds the top corners.
                PhotoCarousel(photos: review.photoUrls, height: 200, cornerRadius: 0)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    // Tapping the spot name opens its detail (resolved from spotId).
                    NavigationLink(value: review.spotId) {
                        Text(review.spotName ?? "Spot")
                            .font(.sHeadingM)
                            .foregroundStyle(Color.sTextPrimary)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: Spacing.sm)

                    optionsMenu
                }

                locationRow

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
        .overlay { deletingOverlay }
        .disabled(isDeleting)
        .animation(.easeInOut(duration: 0.15), value: isDeleting)
    }

    // MARK: - Deleting overlay

    @ViewBuilder
    private var deletingOverlay: some View {
        if isDeleting {
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.sSurface.opacity(0.6))
                .overlay {
                    ProgressView()
                        .tint(Color.sAccent)
                }
        }
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

    // MARK: - Location

    /// The spot's public city + admin area ("Seattle, WA"), denormalized onto the
    /// review. Always present from the backend.
    private var locationRow: some View {
        Label {
            Text("\(review.city), \(review.adminArea)")
        } icon: {
            Image(systemName: "mappin.and.ellipse")
        }
        .font(.sBodyS)
        .foregroundStyle(Color.sTextSecondary)
        .lineLimit(1)
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
                .lineLimit(notesLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .background {
                    // Measure the same text unconstrained; if it's taller than the
                    // clamped version, the notes overflow and need "See more".
                    Text(notes)
                        .font(.sBody)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(key: FullHeightKey.self, value: proxy.size.height)
                            }
                        }
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: ClampedHeightKey.self, value: proxy.size.height)
                    }
                }
                .onPreferenceChange(FullHeightKey.self) { fullNotesHeight = $0 }
                .onPreferenceChange(ClampedHeightKey.self) { clampedNotesHeight = $0 }

            // Only offer "See more" when the notes are actually truncated.
            if isNotesTruncated {
                // Stubbed for now — opens the full review once wired.
                Button {} label: {
                    Text("See more")
                        .font(.sHeadingS)
                        .foregroundStyle(Color.sTextPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// True once the full notes render taller than the 2-line clamp.
    private var isNotesTruncated: Bool {
        fullNotesHeight > clampedNotesHeight + 1
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

// MARK: - Truncation measurement

/// Height of the notes clamped to `notesLineLimit`.
private struct ClampedHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Height the notes would take with no line limit.
private struct FullHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Preview

#Preview("Profile Review Card") {
    NavigationStack {
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
}
