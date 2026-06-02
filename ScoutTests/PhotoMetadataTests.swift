import Testing
import Foundation
import CoreGraphics
import ImageIO
@testable import Scout

struct PhotoMetadataTests {

    /// Encodes a tiny JPEG carrying the given image properties, so we can
    /// round-trip real EXIF/GPS/TIFF through `PhotoMetadata(data:)`.
    private func makeImageData(properties: [CFString: Any]) -> Data {
        let width = 4, height = 2
        let context = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = context.makeImage()!

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data as CFMutableData, "public.jpeg" as CFString, 1, nil
        )!
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    @Test func extractsGPSCameraAndDimensions() {
        let data = makeImageData(properties: [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 34.0522,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 118.2437,
                kCGImagePropertyGPSLongitudeRef: "W",
            ] as [CFString: Any],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifFNumber: 2.8,
                kCGImagePropertyExifISOSpeedRatings: [200],
                kCGImagePropertyExifFocalLength: 35.0,
                kCGImagePropertyExifExposureTime: 0.004,
            ] as [CFString: Any],
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "Apple",
                kCGImagePropertyTIFFModel: "iPhone 16 Pro",
            ] as [CFString: Any],
        ])

        let meta = PhotoMetadata(data: data)

        #expect(meta.pixelWidth == 4)
        #expect(meta.pixelHeight == 2)
        // GPS stored as rationals, so compare with tolerance.
        #expect(abs((meta.latitude ?? 0) - 34.0522) < 0.001)
        // West longitude must come back negative.
        #expect((meta.longitude ?? 0) < 0)
        #expect(abs((meta.longitude ?? 0) + 118.2437) < 0.001)
        #expect(meta.hasLocation)
        #expect(meta.coordinate != nil)

        #expect(meta.iso == 200)
        #expect(abs((meta.fNumber ?? 0) - 2.8) < 0.01)
        #expect(abs((meta.focalLength ?? 0) - 35.0) < 0.01)
        #expect(meta.cameraMake == "Apple")
        #expect(meta.cameraModel == "iPhone 16 Pro")
        #expect(meta.shutterSpeedText == "1/250s")
        #expect(meta.apertureText == "f/2.8")
        #expect(meta.focalLengthText == "35mm")
        #expect(meta.isoText == "ISO 200")
    }

    @Test func nonImageDataYieldsEmptyMetadata() {
        let meta = PhotoMetadata(data: Data([0x00, 0x01, 0x02, 0x03]))

        #expect(meta.latitude == nil)
        #expect(meta.longitude == nil)
        #expect(!meta.hasLocation)
        #expect(meta.coordinate == nil)
        #expect(meta.cameraModel == nil)
        #expect(meta.shutterSpeedText == nil)
    }
}
