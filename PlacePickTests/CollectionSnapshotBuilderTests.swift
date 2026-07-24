import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct CollectionSnapshotBuilderTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func snapshotCarriesCollectionNameAndIconAsSuggestions() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Tokyo Trip", icon: "airplane")

        let snapshot = CollectionSnapshotBuilder.makeSnapshot(for: collection, modelContext: context)

        #expect(snapshot.suggestedName == "Tokyo Trip")
        #expect(snapshot.suggestedIcon == "airplane")
    }

    @Test func snapshotIncludesOnlyPlaceIdentityFields() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Tokyo Trip", icon: "airplane")
        let place = Place(
            appleMapIdentifier: "apple-123",
            name: "Ichiran Shibuya",
            latitude: 35.6595,
            longitude: 139.7005,
            collection: collection,
            isFavorite: true
        )
        context.insert(place)

        let snapshot = CollectionSnapshotBuilder.makeSnapshot(for: collection, modelContext: context)

        #expect(snapshot.places.count == 1)
        #expect(snapshot.places.first?.appleMapIdentifier == "apple-123")
        #expect(snapshot.places.first?.name == "Ichiran Shibuya")
        #expect(snapshot.places.first?.latitude == 35.6595)
        #expect(snapshot.places.first?.longitude == 139.7005)
    }

    @Test func snapshotExcludesPlacesFromOtherCollections() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let included = repository.create(name: "Tokyo Trip", icon: "airplane")
        let excluded = repository.create(name: "Home", icon: "house")
        context.insert(Place(appleMapIdentifier: "a", name: "In Trip", latitude: 0, longitude: 0, collection: included))
        context.insert(Place(appleMapIdentifier: "b", name: "Not In Trip", latitude: 0, longitude: 0, collection: excluded))

        let snapshot = CollectionSnapshotBuilder.makeSnapshot(for: included, modelContext: context)

        #expect(snapshot.places.map(\.name) == ["In Trip"])
    }

    @Test func snapshotExcludesSoftDeletedPlaces() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Tokyo Trip", icon: "airplane")
        let place = Place(appleMapIdentifier: "a", name: "Gone", latitude: 0, longitude: 0, collection: collection)
        context.insert(place)
        PlaceRepository(modelContext: context).softDelete(place)

        let snapshot = CollectionSnapshotBuilder.makeSnapshot(for: collection, modelContext: context)

        #expect(snapshot.places.isEmpty)
    }

    @Test func emptyCollectionProducesEmptySnapshot() throws {
        let context = try makeContext()
        let repository = CollectionRepository(modelContext: context)
        let collection = repository.create(name: "Empty", icon: "tray")

        let snapshot = CollectionSnapshotBuilder.makeSnapshot(for: collection, modelContext: context)

        #expect(snapshot.places.isEmpty)
    }
}
