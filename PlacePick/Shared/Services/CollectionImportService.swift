import Foundation
import SwiftData

/// Result of importing a Collection Snapshot. See MVP.md §11.4 "Existing Places During
/// Collection Import" — the summary counts are intentional: fewer Places than the sender's
/// Collection is expected, not an error.
struct CollectionImportResult {
    let collection: PlaceCollection
    let newPlaceCount: Int
    let alreadySavedCount: Int
}

/// Imports a SharedCollectionSnapshot per MVP.md §11. Only Place identities travel; the
/// receiver always chooses New vs. Merge, and only new Place identities are added —
/// existing local Places, their Collection membership, and their Personal Relationships
/// are never touched. See §11.6 "No Collection Synchronization".
@MainActor
final class CollectionImportService {
    private let placeCreationService: PlaceCreationService
    private let collectionRepository: CollectionRepository

    init(placeCreationService: PlaceCreationService, collectionRepository: CollectionRepository) {
        self.placeCreationService = placeCreationService
        self.collectionRepository = collectionRepository
    }

    /// §11.2 Import as New Collection — creates a brand new local Collection using the
    /// received name/icon only as an initial suggestion.
    func importAsNewCollection(_ snapshot: SharedCollectionSnapshot) -> CollectionImportResult {
        let collection = collectionRepository.create(name: snapshot.suggestedName, icon: snapshot.suggestedIcon)
        return addNewPlaces(from: snapshot, into: collection)
    }

    /// §11.3 Merge into Existing Collection — the destination Collection's name, icon,
    /// and order are preserved; only new Place identities are added.
    func mergeIntoExistingCollection(_ snapshot: SharedCollectionSnapshot, destination: PlaceCollection) -> CollectionImportResult {
        addNewPlaces(from: snapshot, into: destination)
    }

    private func addNewPlaces(from snapshot: SharedCollectionSnapshot, into collection: PlaceCollection) -> CollectionImportResult {
        var newCount = 0
        var alreadySavedCount = 0

        for identity in snapshot.places {
            switch placeCreationService.createPlace(from: identity, collection: collection) {
            case .created:
                newCount += 1
            case .existing:
                alreadySavedCount += 1
            }
        }

        return CollectionImportResult(collection: collection, newPlaceCount: newCount, alreadySavedCount: alreadySavedCount)
    }
}
