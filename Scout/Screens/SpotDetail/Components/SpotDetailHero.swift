import SwiftUI

/// Full-bleed swipeable photo carousel for the top of the Spot Detail screen.
/// The floating back / share / save controls live in `SpotDetailControls`,
/// overlaid by the screen so they stay pinned while the page scrolls beneath.
struct SpotDetailHero: View {
    let photos: [URL]

    @State private var page = 0

    var body: some View {
        Group {
            if photos.isEmpty {
                Color.sAccentSoft
            } else {
                TabView(selection: $page) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: Color.sBorderSubtle
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .frame(height: 320)
        // Pin the carousel to the scroll container's width. A paged TabView has
        // no intrinsic width, so without this it can resolve wider than the
        // screen and drag the whole leading-aligned VStack with it.
        .containerRelativeFrame(.horizontal)
        .clipped()
    }
}
