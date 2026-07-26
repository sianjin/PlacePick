import Foundation
import MapKit

@MainActor
final class MapSearchService: NSObject, ObservableObject {
    @Published var completions: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = [.pointOfInterest, .address]
        completer.delegate = self
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    /// Biases completer results toward this region so a nearby match ranks above an
    /// equally-named match elsewhere, without excluding far-away results outright.
    func updateRegion(around coordinate: CLLocationCoordinate2D) {
        completer.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
    }

    func resolve(_ completion: MKLocalSearchCompletion) async throws -> MKMapItem {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw MapSearchError.noResult
        }
        return item
    }
}

enum MapSearchError: Error {
    case noResult
}

extension MapSearchService: @preconcurrency MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
    }
}
