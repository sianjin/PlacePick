import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreLocation

/// Reads capture time and GPS directly from image EXIF/GPS metadata, independent of the
/// Photos library or any PHAsset lookup. Used as the primary metadata source for
/// Memory Creation so it works purely from PhotosPickerItem-provided data — see
/// DATA_MODEL.md §8.2 "capturedAt": MomentMap must not substitute import/current time.
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

    /// EXIF's DateTimeOriginal/TIFFDateTime is a naive local-time string with no UTC offset
    /// of its own — getting the true instant right means finding that offset from elsewhere,
    /// in order of how exact each source is:
    /// 1. ExifOffsetTimeOriginal/ExifOffsetTime — modern iPhones (iOS 11+) write this
    ///    explicit UTC offset directly alongside DateTimeOriginal. When present it's exact,
    ///    no geocoding or guessing involved.
    /// 2. GPSTimeStamp+GPSDateStamp — GPS time is always UTC by the EXIF spec, so if a GPS
    ///    fix exists, subtracting it from the naive local string yields the exact offset
    ///    that was in effect, again with no guessing.
    /// 3. Time zone resolved from the GPS coordinate — used only when neither of the above
    ///    is available; an approximation (assumes the coordinate's *current* zone rules
    ///    applied at capture time, which is usually but not always true).
    /// Falling back straight to this device's current time zone (as this code used to do)
    /// is wrong whenever the photo was taken somewhere in a different zone — e.g. a NYC
    /// photo reviewed from a Pacific-time device would shift by the zone difference.
    private static func captureDate(from properties: [CFString: Any], latitude: Double?, longitude: Double?) async -> Date? {
        guard let raw = rawLocalDateTimeString(from: properties) else { return nil }

        let naiveFormatter = DateFormatter()
        naiveFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        naiveFormatter.timeZone = TimeZone(identifier: "UTC")
        guard let naiveDate = naiveFormatter.date(from: raw) else { return nil }

        if let offsetSeconds = exifUTCOffsetSeconds(from: properties) {
            return naiveDate.addingTimeInterval(-TimeInterval(offsetSeconds))
        }

        if let gpsUTCDate = gpsUTCDate(from: properties) {
            return gpsUTCDate
        }

        var timeZone = TimeZone.current
        if let latitude, let longitude {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            timeZone = await PlaceTimeZoneResolver.resolve(for: coordinate) ?? .current
        }
        return naiveDate.addingTimeInterval(-TimeInterval(timeZone.secondsFromGMT(for: naiveDate)))
    }

    private static func rawLocalDateTimeString(from properties: [CFString: Any]) -> String? {
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let raw = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            return raw
        }
        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let raw = tiff[kCGImagePropertyTIFFDateTime] as? String {
            return raw
        }
        return nil
    }

    /// Parses "+HH:MM" / "-HH:MM" (the EXIF 2.31+ offset format iOS writes) into seconds
    /// east of UTC, matching Foundation's TimeZone.secondsFromGMT sign convention.
    private static func exifUTCOffsetSeconds(from properties: [CFString: Any]) -> Int? {
        guard let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let raw = (exif[kCGImagePropertyExifOffsetTimeOriginal] as? String)
                ?? (exif[kCGImagePropertyExifOffsetTime] as? String)
        else { return nil }

        let sign: Int
        var digits = raw
        if raw.hasPrefix("-") {
            sign = -1
            digits.removeFirst()
        } else if raw.hasPrefix("+") {
            sign = 1
            digits.removeFirst()
        } else {
            sign = 1
        }

        let parts = digits.split(separator: ":")
        guard parts.count == 2, let hours = Int(parts[0]), let minutes = Int(parts[1]) else { return nil }
        return sign * (hours * 3600 + minutes * 60)
    }

    private static func gpsUTCDate(from properties: [CFString: Any]) -> Date? {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let dateStamp = gps[kCGImagePropertyGPSDateStamp] as? String,
              let timeStamp = gps[kCGImagePropertyGPSTimeStamp] as? String
        else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: "\(dateStamp) \(timeStamp)")
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
