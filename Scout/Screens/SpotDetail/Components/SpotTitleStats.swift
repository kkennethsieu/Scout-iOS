import SwiftUI

/// Spot name + subtitle, sitting directly below the hero.
struct SpotTitleBlock: View {
    let name: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(name)
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)
            Text(subtitle)
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
        }
    }
}

/// The rating / distance stat row with hairline dividers above and below.
struct SpotStatsRow: View {
    let rating: String
    let distance: String

    var body: some View {
        HStack(spacing: 0) {
            stat(value: rating, label: "RATING", icon: "star.fill", iconColor: Color.sWarning)
            Divider().frame(height: 36)
            stat(value: distance, label: "AWAY", icon: "location", iconColor: Color.sTextSecondary)
        }
        .overlay(Divider(), alignment: .top)
        .overlay(Divider(), alignment: .bottom)
        .padding(.vertical, Spacing.md)
    }

    private func stat(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
            }
            Text(label)
                .font(.sCaption)
                .foregroundStyle(Color.sTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
