import Foundation
import MapKit

/// Suggests Apple Maps candidates near a PhotoImportGroup's approximate coordinate.
/// See MEMORY_CREATION.md Stage 3 "Confirm Places" — this only proposes; the user always
/// confirms or picks a different result. See DATA_MODEL.md §13: location metadata narrows
/// the search, it never decides Place identity on its own.
enum NearbyPlaceSearchService {
    private static let searchRadiusMeters: CLLocationDistance = 200

    static func nearbyPlaces(around coordinate: CLLocationCoordinate2D) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: searchRadiusMeters, longitudinalMeters: searchRadiusMeters)
        // POI-only excludes any coordinate Apple Maps hasn't tagged as a formal point of
        // interest — many real photo locations (trailheads, scenic spots, addresses,
        // unlisted parks) have valid GPS but no POI listing, so they'd never get a
        // suggestion even though Photos itself can show the location on a map.
        request.resultTypes = [.pointOfInterest, .address]

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
