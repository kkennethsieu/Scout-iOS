import SwiftUI

struct PhotoCarousel: View {
    /// A carousel image source — a remote URL or already-loaded local bytes.
    enum Source: Hashable {
        case remote(URL)
        case local(Data)
    }

    private let sources: [Source]
    var height: CGFloat = 220
    var cornerRadius: CGFloat = Radius.lg

    @State private var page = 0

    /// Remote photos (Explore cards, spot detail).
    init(photos: [URL], height: CGFloat = 220, cornerRadius: CGFloat = Radius.lg) {
        self.sources = photos.map(Source.remote)
        self.height = height
        self.cornerRadius = cornerRadius
    }

    /// Local photos held in memory (e.g. the just-uploaded review images on the
    /// success screen) — rendered instantly with no network fetch.
    init(photos: [Data], height: CGFloat = 220, cornerRadius: CGFloat = Radius.lg) {
        self.sources = photos.map(Source.local)
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        carousel
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(alignment: .bottom) {
                if sources.count > 1 {
                    pageDots.padding(.bottom, Spacing.md)
                }
            }
    }

    @ViewBuilder
    private var carousel: some View {
        if sources.isEmpty {
            placeholder
        } else if sources.count == 1 {
            photo(sources[0])
        } else {
            TabView(selection: $page) {
                ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                    photo(source).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    @ViewBuilder
    private func photo(_ source: Source) -> some View {
        switch source {
        case .remote(let url): asyncPhoto(url)
        case .local(let data): localPhoto(data)
        }
    }

    private func localPhoto(_ data: Data) -> some View {
        // Color base + overlay + clip so a decoded image can't stretch the frame.
        Color.sBorderSubtle
            .overlay {
                if let image = Image(data: data) {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
            .clipped()
    }

    private func asyncPhoto(_ url: URL) -> some View {
        Color.sBorderSubtle
            .overlay {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure: placeholder
                    case .empty: ProgressView()
                    @unknown default: placeholder
                    }
                }
            }
            .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Color.sAccentSoft
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(Color.sTextTertiary)
        }
    }

    private var pageDots: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(sources.indices, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index == page ? 1 : 0.5))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(.black.opacity(0.25), in: Capsule())
    }
}
