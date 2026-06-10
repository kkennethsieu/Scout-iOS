import SwiftUI

/// 3-column 1:1 photo grid for the Profile "Photos" tab (design system §6.6).
/// Uses the codebase's `Color` base + overlay + `.clipped()` pattern so a
/// loaded image's native size can't blow out its tile.
struct ProfilePhotoGrid: View {
    let photoURLs: [URL]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(photoURLs, id: \.self) { url in
                Color.sBorderSubtle
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.sBorderSubtle
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
    }
}

// MARK: - Preview

#Preview("Profile Photo Grid") {
    ScrollView {
        ProfilePhotoGrid(photoURLs: ProfileViewModel.samplePhotoURLs)
            .padding(Spacing.lg)
    }
    .background(Color.sBackground)
}
