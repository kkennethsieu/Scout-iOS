import SwiftUI

/// 2×2 grid of fact pills (Access · Best Season · Entrance Fee · Crowd Level).
struct SpotQuickFacts: View {
    let detail: SpotDetail

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        SSection(title: "Quick Facts") {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                factPill(icon: "info.circle", value: detail.modeAccessLevel ?? "—", label: "Access")
                factPill(icon: "calendar", value: detail.seasonsText, label: "Best Season")
                factPill(icon: "tag", value: detail.modeEntranceFee ?? "—", label: "Entrance Fee")
                factPill(icon: "person.2", value: detail.modeCrowdLevel ?? "—", label: "Crowd Levels")
            }
        }
    }

    private func factPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.sTextPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
                Text(label)
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
    }
}
