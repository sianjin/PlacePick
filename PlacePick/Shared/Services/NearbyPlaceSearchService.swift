import Foundation
import MapKit

/// Suggests Apple Maps candidates near a PhotoImportGroup's approximate coordinate.
/// See MEMORY_CREATION.md Stage 3 "Confirm Places" — this only proposes; the user always
/// confirms or picks a different result. See DATA_MODEL.md §13: location metadata narrows
/// the search, it never decides Place identity on its own.
enum NearbyPlaceSearchService {
    private static let searchRadiusMeters: CLLocationDistance = 200

    /// MKLocalSearch.Request needs a naturalLanguageQuery to reliably return results —
    /// with only a region and resultTypes set (no query text), Apple's API frequently
    /// returns zero results even in places with plenty of real POIs. MKLocalPointsOfInterestRequest
    /// is the API actually designed for "what's near this coordinate," with no text query
    /// required, and reliably surfaces results MKLocalSearch silently missed.
    static func nearbyPlaces(around coordinate: CLLocationCoordinate2D) async -> [MKMapItem] {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: searchRadiusMeters)

        let search = MKLocalSearch(request: request)
        guard let response = try? await search.start() else { return [] }

        return response.mapItems.sorted { lhs, rhs in
            distance(from: coordinate, to: lhs) < distance(from: coordinate, to: rhs)
        }
    }

    private static func distance(from coordinate: CLLocationCoordinate2D, to mapItem: MKMapItem) -> CLLocationDistance {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: mapItem.placemark.coordinate.latitude, longitude: mapItem.placemark.coordinate.longitude))
    }
}
