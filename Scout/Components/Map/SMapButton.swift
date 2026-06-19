import SwiftUI

/// A floating accent pill with a map icon — a "view these on a map" affordance.
/// Overlay it at the bottom of any screen that has spots to show (a saved list,
/// search results, …). Shares the floating-pill language of `SearchAreaButton`.
struct SMapButton: View {
    var title: String = "Map"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "map")
                Text(title)
            }
            .font(.sHeadingS)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Capsule().fill(Color.sAccent))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("SMapButton") {
    ZStack {
        Color.sAccentSoft.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            SMapButton {}
            SMapButton(title: "View on map") {}
        }
    }
}
