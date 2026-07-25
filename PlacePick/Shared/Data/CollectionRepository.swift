import Foundation
import SwiftData

enum CollectionDeletionError: Error {
    /// Places must be reassigned to another Collection before this one can be deleted.
    case containsPlaces
    case destinationIsSameCollection
}

@MainActor
final class CollectionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllOrdered() -> [PlaceCollection] {
        let descriptor = FetchDescriptor<PlaceCollection>(sortBy: [SortDescriptor(\.order)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    @discardableResult
    func create(name: String, icon: String) -> PlaceCollection {
        let nextOrder = (fetchAllOrdered().map(\.order).max() ?? -1) + 1
        let collection = PlaceCollection(name: name, icon: icon, order: nextOrder)
        modelContext.insert(collection)
        try? modelContext.save()
        return collection
    }

    func seedSuggestedCollectionsIfNeeded() {
        guard fetchAllOrdered().isEmpty else { return }
        guard !UserDefaults.standard.bool(forKey: hasSeededSuggestionsKey) else { return }

        for (index, suggestion) in SuggestedCollection.allCases.enumerated() {
            modelContext.insert(PlaceCollection(name: suggestion.name, icon: suggestion.icon, order: index))
        }
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: hasSeededSuggestionsKey)
    }

    func rename(_ collection: PlaceCollection, to name: String) {
        collection.name = name
        try? modelContext.save()
    }

    func setIcon(_ collection: PlaceCollection, to icon: String) {
        collection.icon = icon
        try? modelContext.save()
    }

    func reorder(_ collections: [PlaceCollection]) {
        for (index, collection) in collections.enumerated() {
            collection.order = index
        }
        try? modelContext.save()
    }

    func placeCount(for collection: PlaceCollection) -> Int {
        let collectionID = collection.id
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.collection?.id == collectionID && $0.deletedAt == nil }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Deletes an empty Collection, or reassigns its Places to `destination` first and deletes atomically.
    func delete(_ collection: PlaceCollection, reassigningTo destination: PlaceCollection?) throws {
        let count = placeCount(for: collection)

        if count > 0 {
            guard let destination else {
                throw CollectionDeletionError.containsPlaces
            }
            guard destination.id != collection.id else {
                throw CollectionDeletionError.destinationIsSameCollection
            }

            let collectionID = collection.id
            let descriptor = FetchDescriptor<Place>(
                predicate: #Predicate { $0.collection?.id == collectionID && $0.deletedAt == nil }
            )
            let affectedPlaces = (try? modelContext.fetch(descriptor)) ?? []
            for place in affectedPlaces {
                place.collection = destination
                place.modifiedAt = .now
            }
        }

        modelContext.delete(collection)
        try? modelContext.save()
    }

    private let hasSeededSuggestionsKey = "com.sianjin.PlacePick.hasSeededSuggestedCollections"
}
