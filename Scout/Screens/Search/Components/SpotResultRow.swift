import SwiftUI

/// A single Scout spot in the search results "Spots" section: a leading SF Symbol
/// tile, the spot name with the matched query run bolded, its locality, and a
/// rating line. Tapping it opens the spot's detail screen.
struct SpotResultRow: View {
    let spot: SpotSummary
    /// The active query, used to bold the matching run of the name.
    var query: String = ""

    var body: some View {
        HStack(spacing: Spacing.md) {
            icon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(highlightedName)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)

                if let region {
                    Text(region)
                        .font(.sBody)
                        .foregroundStyle(Color.sTextSecondary)
                        .lineLimit(1)
                }

                rating
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private var icon: some View {
        Image(systemName: "mappin")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.sAccent)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.sAccentSoft)
            )
    }

    private var rating: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.sWarning)
            Text(spot.avgRating.formatted(.number.precision(.fractionLength(1))))
                .foregroundStyle(Color.sTextPrimary)
            Text("(\(spot.reviewCount))")
                .foregroundStyle(Color.sTextSecondary)
        }
        .font(.sBodyS)
    }

    /// Bolds the first case-insensitive occurrence of the query within the name.
    private var highlightedName: AttributedString {
        var attributed = AttributedString(spot.name)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let range = spot.name.range(of: trimmed, options: .caseInsensitive),
              let attrRange = Range(range, in: attributed) else {
            return attributed
        }
        if let prefix = Range(spot.name.startIndex..<range.lowerBound, in: attributed) {
            attributed[prefix].foregroundColor = .sTextSecondary
        }
        if let suffix = Range(range.upperBound..<spot.name.endIndex, in: attributed) {
            attributed[suffix].foregroundColor = .sTextSecondary
        }
        return attributed
    }

    private var region: String? {
        let place = [spot.city, spot.adminArea]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return place.isEmpty ? nil : place
    }
}

// MARK: - Preview

#Preview("Spot Result Row") {
    VStack(spacing: Spacing.lg) {
        SpotResultRow(spot: .sample(name: "Cedar Cathedral"), query: "ced")
        SpotResultRow(spot: .sample(name: "Mirror Reservoir", rating: 4.7), query: "")
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.sBackground)
}
