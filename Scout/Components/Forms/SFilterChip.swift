import SwiftUI

/// A single selectable pill used in horizontal filter rows (Explore).
/// Selected: `sAccent` fill with white text. Unselected: surface with border.
struct SFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sHeadingS)
                .foregroundStyle(isSelected ? .white : Color.sTextPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .fill(isSelected ? Color.sAccent : Color.sSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .stroke(Color.sBorderDefault, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview

#Preview("Filter Chips") {
    HStack(spacing: Spacing.sm) {
        SFilterChip(title: "All Spots", isSelected: true) {}
        SFilterChip(title: "Forest", isSelected: false) {}
        SFilterChip(title: "Coast", isSelected: false) {}
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
