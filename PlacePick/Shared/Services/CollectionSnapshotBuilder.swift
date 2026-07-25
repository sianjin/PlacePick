import Foundation
import SwiftData

/// Builds a portable snapshot of a Collection for sharing. See DATA_MODEL.md "Shared
/// Collection Snapshot" — only Place Identity travels; Favorite, Emotion, Note, and
/// Memory Photo never leave the local database.
@MainActor
enum CollectionSnapshotBuilder {
    static func makeSnapshot(for collection: PlaceCollection, modelContext: ModelContext) -> SharedCollectionSnapshot {
        let collectionID = collection.id
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.collection?.id == collectionID && $0.deletedAt == nil }
        )
        let places = (try? modelContext.fetch(descriptor)) ?? []

        return SharedCollectionSnapshot(
            suggestedName: collection.name,
            suggestedIcon: collection.icon,
            places: places.map(\.sharedIdentity)
        )
    }
}
