import SwiftUI

/// Full-bleed swipeable photo carousel for the top of the Spot Detail screen,
/// with floating back / share / save controls.
struct SpotDetailHero: View {
    let photos: [URL]
    @Binding var isSaved: Bool
    var onBack: () -> Void
    var onShare: () -> Void

    @State private var page = 0

    var body: some View {
        ZStack(alignment: .top) {
            carousel

            HStack {
                circleIcon("chevron.left", action: onBack)
                Spacer()
                HStack(spacing: Spacing.md) {
                    circleIcon("square.and.arrow.up", action: onShare)
                    circleIcon(isSaved ? "bookmark.fill" : "bookmark") { isSaved.toggle() }
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
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .frame(height: 320)
        .clipped()
    }

    private func circleIcon(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.sTextPrimary)
                .frame(width: 40, height: 40)
                .background(Color.sSurface.opacity(0.92), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
