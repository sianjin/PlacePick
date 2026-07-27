import SwiftUI
import SwiftData
import MapKit

/// Reuses the same MapKit search experience as Add Place, per PLACE_CREATION.md §8.2 / §7.4:
/// "Do not create a second search implementation." ManualPlaceSearchSheet offers both a
/// search bar and a mini-map centered on the Place's current location, so a wrong pin can be
/// corrected by tapping the right one directly, not just by re-typing the name.
struct ReplacePlaceScreen: View {
    let place: Place
    /// Called with the pre-existing target Place if the new selection already belongs to
    /// another saved Place, or nil once the flow is dismissed with no replacement conflict.
    let onFinished: (Place?) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var nearbySuggestions: [MKMapItem] = []
    @State private var pendingMapItem: MKMapItem?
    @State private var errorMessage: String?

    var body: some View {
        ManualPlaceSearchSheet(
            nearbyCoordinate: place.coordinate,
            nearbySuggestions: nearbySuggestions
        ) { mapItem in
            pendingMapItem = mapItem
        }
        .task {
            nearbySuggestions = await NearbyPlaceSearchService.nearbyPlaces(around: place.coordinate)
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: Binding(
                get: { pendingMapItem != nil },
                set: { if !$0 { pendingMapItem = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Replace") { confirmReplace() }
            Button("Cancel", role: .cancel) { pendingMapItem = nil }
        } message: {
            Text("Your note, emotion, favorite, and memory photo will be kept.")
        }
        .alert("We couldn't replace this place", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private var confirmationTitle: String {
        "Replace this place with \"\(pendingMapItem?.name ?? "")\"?"
    }

    private func confirmReplace() {
        guard let mapItem = pendingMapItem else { return }
        let repository = PlaceRepository(modelContext: modelContext)
        let creationService = PlaceCreationService(repository: repository)

        do {
            let result = try creationService.replaceIdentity(for: place, with: mapItem)
            switch result {
            case .replaced:
                onFinished(nil)
            case .existingTarget(let existing):
                onFinished(existing)
            }
        } catch {
            errorMessage = "We couldn't resolve that place. Try another search."
        }
    }
}
