import SwiftUI

/// A nearby existing spot on the create-flow map: the shared `SpotMapMarker` with
/// the spot's name on a capsule label beneath it. (The Map tab uses `SpotMapMarker`
/// without a label, so the labelled variant lives here.)
struct NearbySpotMarker: View {
    let name: String
    var isSelected: Bool = false
    private var size: CGFloat { isSelected ? 40 : 32 }

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "camera.fill")
                .font(.system(size: isSelected ? 16 : 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Color.sAccent, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                .animation(.spring(duration: 0.25), value: isSelected)
        }
            Text(name)
                .font(.sCaption)
                .foregroundStyle(Color.sTextPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                .fixedSize()
        }
}

// MARK: - Preview

#Preview("Nearby Spot Marker") {
    HStack(spacing: Spacing.xl) {
        NearbySpotMarker(name: "Cedar Cathedral")
        NearbySpotMarker(name: "Mirror Reservoir", isSelected: true)
    }
    .padding()
    .background(Color.sBackground)
}
