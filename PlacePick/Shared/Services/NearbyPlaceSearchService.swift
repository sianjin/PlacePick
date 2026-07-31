import Foundation
import MapKit

/// Suggests Apple Maps candidates near a PhotoImportGroup's approximate coordinate.
/// See MEMORY_CREATION.md Stage 2 "Review Groups & Confirm Places" — this only proposes;
/// the user always confirms or picks a different result. See DATA_MODEL.md §13: location metadata narrows
/// the search, it never decides Place identity on its own.
enum NearbyPlaceSearchService {
    // 200m was too tight for large landmarks (e.g. Times Square) whose registered POI
    // coordinate can sit well away from wherever within the landmark the photo was actually
    // taken — the landmark's own pin could fall just outside the radius and never surface
    // as a suggestion at all, regardless of pin-thinning logic downstream.
    private static let searchRadiusMeters: CLLocationDistance = 500

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
