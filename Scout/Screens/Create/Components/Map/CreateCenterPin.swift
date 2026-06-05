import SwiftUI

/// The fixed centre pin for the create-flow map: the map pans underneath while
/// the pin stays put, with a "Drag to adjust" hint floating above it. Purely
/// presentational and non-interactive (the screen disables hit testing).
struct CreateCenterPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Color.sAccent, lineWidth: 3))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            dragHint.offset(y: -36)
        }
    }

    private var dragHint: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 11, weight: .semibold))
            Text("Drag to adjust")
                .font(.sCaption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.black.opacity(0.78), in: Capsule())
        .fixedSize()
    }
}

// MARK: - Preview

#Preview("Create Center Pin") {
    CreateCenterPin()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBorderSubtle)
}
