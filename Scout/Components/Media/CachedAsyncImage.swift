import SwiftUI
import UIKit

/// In-memory cache of decoded images, keyed by URL.
///
/// `NSCache` is thread-safe and evicts under memory pressure, so this is safe to
/// touch from the main actor without holding images forever.
@MainActor
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 250
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

/// A caching, drop-in stand-in for `AsyncImage`.
///
/// Plain `AsyncImage` keeps no cache and cancels its in-flight request whenever
/// SwiftUI re-lays-out the view. In lazy/scrolling containers (the Explore feed,
/// the paged `PhotoCarousel`) the first batch of cards all mount at once, race
/// each other over the shared `URLSession`, get cancelled mid-flight, and stay
/// stuck on the placeholder — until you open the spot (a fresh, uncontended
/// load) and the image "appears." Keying decoded images by URL means a loaded
/// photo renders instantly on reuse and survives view recycling.
///
/// Mirrors the `AsyncImage(url:content:)` phase API so call sites are unchanged.
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder var content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    var body: some View {
        content(phase)
            // Re-runs (and cancels) with view lifecycle; keyed on `url` so a
            // recycled cell reloads for its new URL. A cache hit is synchronous.
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else {
            phase = .empty
            return
        }

        if let cached = ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        // Only reset to the loading state on a genuine cache miss, so a reused
        // cell doesn't flash its placeholder before the cached image lands.
        if case .success = phase {} else { phase = .empty }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                phase = .failure(URLError(.badServerResponse))
                return
            }
            ImageCache.shared.insert(image, for: url)
            phase = .success(Image(uiImage: image))
        } catch {
            // Cancellation just means the cell scrolled off; leave the phase so
            // the next appearance reloads cleanly instead of showing an error.
            if error is CancellationError { return }
            if (error as? URLError)?.code == .cancelled { return }
            phase = .failure(error)
        }
    }
}
