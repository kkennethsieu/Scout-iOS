import Testing
import UIKit
@testable import Scout

@MainActor
struct ImageCacheTests {
    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        return renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    @Test func storesAndRetrievesByURL() {
        let cache = ImageCache.shared
        let url = URL(string: "https://example.com/photo-\(UUID().uuidString).jpg")!
        #expect(cache.image(for: url) == nil)

        let image = makeImage()
        cache.insert(image, for: url)

        #expect(cache.image(for: url) === image)
    }

    @Test func missForUncachedURL() {
        let cache = ImageCache.shared
        let url = URL(string: "https://example.com/never-\(UUID().uuidString).jpg")!
        #expect(cache.image(for: url) == nil)
    }
}
