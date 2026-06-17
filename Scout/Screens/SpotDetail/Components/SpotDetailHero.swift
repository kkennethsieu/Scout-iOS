import SwiftUI

/// Full-bleed swipeable photo carousel for the top of the Spot Detail screen,
/// with floating back / share / save controls.
struct SpotDetailHero: View {
    let photos: [URL]
    var isSaved: Bool
    /// What the share button sends — a link to the spot (e.g. its public Maps
    /// location). The spot name is the share subject/message.
    var shareURL: URL
    var spotName: String
    var onBack: () -> Void
    var onTapSave: () -> Void = {}

    @State private var page = 0

    var body: some View {
        ZStack(alignment: .top) {
            carousel

            HStack {
                circleIcon("chevron.left", action: onBack)
                Spacer()
                HStack(spacing: Spacing.md) {
                    ShareLink(item: shareURL,
                              subject: Text(spotName),
                              message: Text("Check out \(spotName) on Scout")) {
                        iconLabel("square.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                    circleIcon(isSaved ? "bookmark.fill" : "bookmark", action: onTapSave)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, 60)
        }
    }

    @ViewBuilder
    private var carousel: some View {
        Group {
            if photos.isEmpty {
                Color.sAccentSoft
            } else {
                TabView(selection: $page) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.sBorderSubtle
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

    private func circleIcon(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            iconLabel(symbol)
        }
        .buttonStyle(.plain)
    }

    /// The floating-circle icon styling, shared by the buttons and the ShareLink.
    private func iconLabel(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.sTextPrimary)
            .frame(width: 40, height: 40)
            .background(Color.sSurface.opacity(0.92), in: Circle())
    }
}
