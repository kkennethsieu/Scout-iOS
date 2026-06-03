import SwiftUI

/// The "you are here" marker on the map. Brand-accent dot with a soft accuracy
/// halo and a white ring so it reads on any map tile.
struct UserLocationDot: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.sAccent.opacity(0.18))
                .frame(width: 30, height: 30)
            Circle()
                .fill(Color.sAccent)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.white, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        }
    }
}

// MARK: - Preview

#Preview("User Location Dot") {
    UserLocationDot()
        .padding()
        .background(Color.sAccentSoft)
}
