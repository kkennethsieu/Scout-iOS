import SwiftUI

/// The "<count> spots" / "<sort> ▾" row above the feed.
struct ExploreHeaderRow: View {
    let countText: String
    var sortLabel: String = "Sort"
    var onTapSort: () -> Void = {}

    var body: some View {
        HStack {
            Text(countText)
                .font(.sHeadingS)
                .foregroundStyle(Color.sTextSecondary)

            Spacer()

            Button(action: onTapSort) {
                HStack(spacing: Spacing.xs) {
                    Text(sortLabel)
                        .font(.sHeadingS)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.sTextPrimary)
            }
        }
    }
}
