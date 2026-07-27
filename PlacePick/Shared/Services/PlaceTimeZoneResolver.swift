import Foundation
import CoreLocation

/// Looks up the IANA time zone in effect at a coordinate, so a Memory's time can be shown
/// as it truly was at the place visited (e.g. NYC local time) rather than reformatted into
/// whatever time zone the viewing device currently happens to be in. There is no offline
/// coordinate→timezone database in CoreLocation/MapKit, so this goes through CLGeocoder's
/// reverse-geocode, which is network-backed and rate-limited — results are cached per
/// rounded coordinate (~1km) since a Place's timezone never changes between lookups.
@MainActor
enum PlaceTimeZoneResolver {
    private static var cache: [String: TimeZone] = [:]
    private static let geocoder = CLGeocoder()

    private static func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        // ~2 decimal places (~1km) is coarse enough to reuse across nearby Places/photos
        // while never crossing a real timezone boundary within that radius in practice.
        String(format: "%.2f,%.2f", coordinate.latitude, coordinate.longitude)
    }

    /// Returns a cached time zone immediately if already resolved for this coordinate,
    /// else nil — callers should fall back to displaying with the device's current time
    /// zone (today's behavior) until `resolve(for:)` completes and the view refreshes.
    static func cached(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
        cache[cacheKey(for: coordinate)]
    }

    @discardableResult
    static func resolve(for coordinate: CLLocationCoordinate2D) async -> TimeZone? {
        let key = cacheKey(for: coordinate)
        if let cached = cache[key] { return cached }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first,
              let timeZone = placemark.timeZone
        else {
            return nil
        }

        cache[key] = timeZone
        return timeZone
    }
}
