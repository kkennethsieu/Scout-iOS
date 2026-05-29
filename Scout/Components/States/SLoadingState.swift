import SwiftUI

/// Centered loading spinner for full-screen async loads.
struct SLoadingState: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .tint(Color.sAccent)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xxxl)
    }
}

// MARK: - Preview

#Preview("Loading") {
    ZStack {
        Color.sBackground.ignoresSafeArea()
        SLoadingState()
    }
}
