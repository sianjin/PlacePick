import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Reads capture time and GPS directly from image EXIF/GPS metadata, independent of the
/// Photos library or any PHAsset lookup. Used as the primary metadata source for
/// Memory Creation so it works purely from PhotosPickerItem-provided data — see
/// DATA_MODEL.md §8.2 "capturedAt": PlacePick must not substitute import/current time.
enum PhotoMetadataExtractor {
    struct Metadata {
        let capturedAt: Date?
        let latitude: Double?
        let longitude: Double?
    }

    static func extractMetadata(from data: Data) -> Metadata {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return Metadata(capturedAt: nil, latitude: nil, longitude: nil)
        }

        let capturedAt = captureDate(from: properties)
        let (latitude, longitude) = gpsCoordinate(from: properties)

        return Metadata(capturedAt: capturedAt, latitude: latitude, longitude: longitude)
    }

    private static func captureDate(from properties: [CFString: Any]) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let raw = exif[kCGImagePropertyExifDateTimeOriginal] as? String,
           let date = formatter.date(from: raw) {
            return date
        }
        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let raw = tiff[kCGImagePropertyTIFFDateTime] as? String,
           let date = formatter.date(from: raw) {
            return date
        }
        return nil
    }

    private static func gpsCoordinate(from properties: [CFString: Any]) -> (Double?, Double?) {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? Double,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        else {
            return (nil, nil)
        }

        let signedLatitude = latitudeRef == "S" ? -latitude : latitude
        let signedLongitude = longitudeRef == "W" ? -longitude : longitude
        return (signedLatitude, signedLongitude)
    }
}
