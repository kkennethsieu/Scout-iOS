import SwiftUI
import MapKit

/// A single place suggestion from MapKit autocomplete: a leading SF Symbol tile,
/// the place title (matched runs bolded), and the subtitle (region/locality).
struct PlaceResultRow: View {
    let completion: MKLocalSearchCompletion

    var body: some View {
        HStack(spacing: Spacing.md) {
            icon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(highlightedTitle)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)

                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.sBody)
                        .foregroundStyle(Color.sTextSecondary)
                        .lineLimit(1)
                }
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

    /// Dims the title, then restores full emphasis on the runs MapKit reports as
    /// matching the query.
    private var highlightedTitle: AttributedString {
        var attributed = AttributedString(completion.title)
        attributed.foregroundColor = .sTextSecondary
        for value in completion.titleHighlightRanges {
            guard let stringRange = Range(value.rangeValue, in: completion.title),
                  let attrRange = Range(stringRange, in: attributed) else { continue }
            attributed[attrRange].foregroundColor = .sTextPrimary
        }
        return attributed
    }
}

// MARK: - Preview

#Preview("Place Result Row") {
    // MKLocalSearchCompletion can't be constructed directly, so previews of this
    // row are exercised live in SearchScreen.
    Color.sBackground
}
