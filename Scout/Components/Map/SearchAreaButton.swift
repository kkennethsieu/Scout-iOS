import SwiftUI

/// Floating pill that re-queries the backend for the currently visible map area.
/// Shows a spinner while a search is in flight.
struct SearchAreaButton: View {
    var isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Search this area")
            }
            .font(.sHeadingS)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Capsule().fill(Color.sAccent))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("Search Area Button") {
    VStack(spacing: Spacing.lg) {
        SearchAreaButton(isLoading: false) {}
        SearchAreaButton(isLoading: true) {}
    }
    .padding()
    .background(Color.sAccentSoft)
}
