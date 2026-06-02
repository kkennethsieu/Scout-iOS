import SwiftUI

/// A floating circular/rounded map control (recenter, layers, …). Material
/// background so it reads on any map tile. Shared so multiple map surfaces use
/// the same control language; the Map tab's recenter button could adopt this.
struct MapControlButton: View {
    let systemImage: String
    var tint: Color = .sAccent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Map Controls") {
    ZStack {
        Color.sAccentSoft.ignoresSafeArea()
        VStack(spacing: Spacing.sm) {
            MapControlButton(systemImage: "location.fill") {}
            MapControlButton(systemImage: "square.2.stack.3d") {}
        }
    }
}
