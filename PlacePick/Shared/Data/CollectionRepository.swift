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

    /// Seeds default Collections only when the synced store genuinely has none. This must
    /// not use a local flag (e.g. UserDefaults) to remember "already seeded" — that flag is
    /// per-device, but Collections sync via CloudKit, so each device/reinstall would think
    /// it's the first launch and insert its own duplicate batch. Checking the actual synced
    /// data is the only thing that stays consistent across devices.
    func seedSuggestedCollectionsIfNeeded() {
        guard fetchAllOrdered().isEmpty else { return }

        for (index, suggestion) in SuggestedCollection.allCases.enumerated() {
            modelContext.insert(PlaceCollection(name: suggestion.name, icon: suggestion.icon, order: index))
        }
        try? modelContext.save()
    }

    /// One-time cleanup for installs affected by the pre-fix duplicate-seeding bug: several
    /// devices each inserted their own "Food"/"Drink"/etc. batch before seedSuggestedCollectionsIfNeeded
    /// checked synced state, and CloudKit merged all the batches together instead of deduping
    /// them (it has no concept of these rows being "the same" Collection). This merges
    /// same-named Collections into the most-recently-modified survivor (not the lowest
    /// `order` — a freshly reseeded batch on reinstall always has low sequential orders
    /// matching the original default, so picking by order silently reverts any reordering
    /// the user made before reinstalling), reassigning every affected Place before deleting
    /// the rest. Safe to run repeatedly since a store with no duplicates left is a no-op.
    func mergeDuplicateCollections() {
        let groups = Dictionary(grouping: fetchAllOrdered(), by: \.name)
        guard groups.values.contains(where: { $0.count > 1 }) else { return }

        for (_, duplicates) in groups where duplicates.count > 1 {
            let sorted = duplicates.sorted { $0.modifiedAt > $1.modifiedAt }
            let survivor = sorted[0]
            for duplicate in sorted.dropFirst() {
                try? delete(duplicate, reassigningTo: survivor)
            }
        }

        // A merge only decides which row survives per name — it says nothing about how that
        // survivor's `order` (inherited from whichever duplicate happened to carry it) relates
        // to every other Collection's `order` in the set. Re-numbering 0..n by current order
        // preserves relative sequence while guaranteeing no gaps/collisions across the merge.
        reorder(fetchAllOrdered())
    }

    func rename(_ collection: PlaceCollection, to name: String) {
        collection.name = name
        collection.modifiedAt = .now
        try? modelContext.save()
    }

    func setIcon(_ collection: PlaceCollection, to icon: String) {
        collection.icon = icon
        collection.modifiedAt = .now
        try? modelContext.save()
    }

    func reorder(_ collections: [PlaceCollection]) {
        for (index, collection) in collections.enumerated() {
            collection.order = index
            collection.modifiedAt = .now
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
}
