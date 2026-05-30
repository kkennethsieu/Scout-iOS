import SwiftUI

/// A circular map pin with a camera glyph, used for spots on the Map tab.
/// Grows and brightens when selected.
struct SpotMapMarker: View {
    var isSelected: Bool = false

    private var size: CGFloat { isSelected ? 40 : 32 }

    var body: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: isSelected ? 16 : 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.sAccent, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Spot Map Marker") {
    HStack(spacing: Spacing.xl) {
        SpotMapMarker(isSelected: false)
        SpotMapMarker(isSelected: true)
    }
    .padding()
    .background(Color.sBackground)
}
