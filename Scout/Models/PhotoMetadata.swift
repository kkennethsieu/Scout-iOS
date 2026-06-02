import Foundation
import ImageIO
import CoreLocation

/// Camera + location metadata pulled from a picked photo's raw bytes.
///
/// Read straight from the file's embedded EXIF/GPS/TIFF via `ImageIO`, so it
/// works without photo-library access (the `PhotosPicker` only hands us `Data`).
nonisolated struct PhotoMetadata: Equatable {
    var latitude: Double?
    var longitude: Double?
    var capturedAt: Date?
    var cameraMake: String?
    var cameraModel: String?
    var lensModel: String?
    var fNumber: Double?
    var exposureTime: Double?      // seconds
    var iso: Int?
    var focalLength: Double?       // mm
    var focalLengthIn35mm: Int?
    var pixelWidth: Int?
    var pixelHeight: Int?

    init() {}

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasLocation: Bool { latitude != nil && longitude != nil }

    // MARK: - Display helpers

    /// e.g. "1/250s" or "2s".
    var shutterSpeedText: String? {
        guard let exposureTime, exposureTime > 0 else { return nil }
        if exposureTime < 1 {
            return "1/\(Int((1 / exposureTime).rounded()))s"
        }
        return "\(exposureTime.formatted(.number.precision(.fractionLength(0...1))))s"
    }

    /// e.g. "f/2.8".
    var apertureText: String? {
        fNumber.map { "f/\($0.formatted(.number.precision(.fractionLength(0...1))))" }
    }

    /// e.g. "35mm".
    var focalLengthText: String? {
        focalLength.map { "\(Int($0.rounded()))mm" }
    }

    /// e.g. "ISO 200".
    var isoText: String? {
        iso.map { "ISO \($0)" }
    }
}

// MARK: - Extraction

extension PhotoMetadata {
    /// Parses embedded metadata from encoded image `data`. Returns an empty
    /// value (all `nil`) if the data isn't a readable image — never throws.
    init(data: Data) {
        self.init()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return }

        pixelWidth = props[kCGImagePropertyPixelWidth] as? Int
        pixelHeight = props[kCGImagePropertyPixelHeight] as? Int

        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLatitudeRef] as? String
                latitude = (ref == "S") ? -lat : lat
            }
            if let lon = gps[kCGImagePropertyGPSLongitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLongitudeRef] as? String
                longitude = (ref == "W") ? -lon : lon
            }
        }

        if let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            cameraMake = tiff[kCGImagePropertyTIFFMake] as? String
            cameraModel = tiff[kCGImagePropertyTIFFModel] as? String
        }

        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            fNumber = exif[kCGImagePropertyExifFNumber] as? Double
            exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double
            iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first
            focalLength = exif[kCGImagePropertyExifFocalLength] as? Double
            focalLengthIn35mm = exif[kCGImagePropertyExifFocalLenIn35mmFilm] as? Int
            lensModel = exif[kCGImagePropertyExifLensModel] as? String
            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                formatter.timeZone = .current
                capturedAt = formatter.date(from: dateString)
            }
        }
    }
}
