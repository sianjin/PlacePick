import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreLocation

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

    static func extractMetadata(from data: Data) async -> Metadata {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return Metadata(capturedAt: nil, latitude: nil, longitude: nil)
        }

        let (latitude, longitude) = gpsCoordinate(from: properties)
        let capturedAt = await captureDate(from: properties, latitude: latitude, longitude: longitude)

        return Metadata(capturedAt: capturedAt, latitude: latitude, longitude: longitude)
    }

    /// EXIF's DateTimeOriginal/TIFFDateTime is a naive local-time string with no UTC offset —
    /// it must be interpreted using the time zone in effect where the photo was actually
    /// taken, not this device's current time zone (which may be a different zone entirely,
    /// e.g. reviewing NYC photos from a Pacific-time device), or the resulting absolute Date
    /// instant is wrong by the difference between the two zones.
    private static func captureDate(from properties: [CFString: Any], latitude: Double?, longitude: Double?) async -> Date? {
        var timeZone = TimeZone.current
        if let latitude, let longitude {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            timeZone = await PlaceTimeZoneResolver.resolve(for: coordinate) ?? .current
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = timeZone

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
