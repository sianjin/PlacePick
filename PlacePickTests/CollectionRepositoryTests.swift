import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct CollectionRepositoryTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func newCollectionsCanBeCreated() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)

        let collection = repository.create(name: "Beaches", icon: "beach.umbrella")

        #expect(repository.fetchAllOrdered().map(\.id).contains(collection.id))
    }

    @Test func collectionsCanBeRenamed() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Food", icon: "fork.knife")

        repository.rename(collection, to: "Restaurants")

        #expect(collection.name == "Restaurants")
    }

    @Test func collectionsCanBeReordered() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let first = repository.create(name: "Food", icon: "fork.knife")
        let second = repository.create(name: "Beaches", icon: "beach.umbrella")

        repository.reorder([second, first])

        #expect(second.order < first.order)
    }

    @Test func everyPlaceBelongsToExactlyOneCollection() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Food", icon: "fork.knife")

        let place = Place(appleMapIdentifier: "id", name: "Place", latitude: 0, longitude: 0, collection: collection)
        context.insert(place)

        #expect(place.collection.id == collection.id)
    }

    @Test func emptyCollectionCanBeDeletedDirectly() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Food", icon: "fork.knife")

        try repository.delete(collection, reassigningTo: nil)

        #expect(!repository.fetchAllOrdered().map(\.id).contains(collection.id))
    }

    @Test func deletingCollectionWithPlacesRequiresReassignment() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Food", icon: "fork.knife")
        let place = Place(appleMapIdentifier: "id", name: "Place", latitude: 0, longitude: 0, collection: collection)
        context.insert(place)

        #expect(throws: CollectionDeletionError.containsPlaces) {
            try repository.delete(collection, reassigningTo: nil)
        }
    }

    @Test func deletingCollectionReassignsPlacesToDestination() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let source = repository.create(name: "Food", icon: "fork.knife")
        let destination = repository.create(name: "Drink", icon: "cup.and.saucer")
        let place = Place(appleMapIdentifier: "id", name: "Place", latitude: 0, longitude: 0, collection: source)
        context.insert(place)

        try repository.delete(source, reassigningTo: destination)

        #expect(place.collection.id == destination.id)
        #expect(!repository.fetchAllOrdered().map(\.id).contains(source.id))
    }
}
