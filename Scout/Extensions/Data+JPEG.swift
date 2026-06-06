import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

extension Data {
    /// Re-encodes image bytes as a compressed JPEG, downscaling so the longest
    /// edge is at most `maxPixel`. Handles HEIC/HEIF → JPEG (the create endpoint
    /// accepts JPEG only) and bakes in the source's EXIF orientation. Returns
    /// `nil` if the bytes aren't a decodable image.
    ///
    /// Uses ImageIO (cross-platform) rather than UIKit so it compiles on every
    /// supported platform. The thumbnail re-encode drops EXIF/GPS metadata.
    nonisolated func jpegForUpload(maxPixel: Int = 2048, quality: CGFloat = 0.8) -> Data? {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // bake in orientation
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
