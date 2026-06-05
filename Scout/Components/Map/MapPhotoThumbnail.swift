import SwiftUI

/// The floating source-photo thumbnail shown over the create-flow map (top-right),
/// reminding the user which photo they're placing. Renders nothing when there's no
/// photo (e.g. the "use current location" entry).
struct MapPhotoThumbnail: View {
    let image: Image?

    var body: some View {
        if let image {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
    }
}

// MARK: - Preview

#Preview("Map Photo Thumbnail") {
    MapPhotoThumbnail(image: Image(systemName: "photo"))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBorderSubtle)
}
