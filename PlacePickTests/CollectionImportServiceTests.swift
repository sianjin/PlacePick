import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct CollectionImportServiceTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makeService(context: ModelContext) -> CollectionImportService {
        CollectionImportService(
            placeCreationService: PlaceCreationService(repository: PlaceRepository(modelContext: context)),
            collectionRepository: CollectionRepository(modelContext: context)
        )
    }

    @Test func importAsNewCollectionCreatesCollectionWithSuggestedNameAndIcon() throws {
        let context = try makeContext()
        let service = makeService(context: context)
        let snapshot = SharedCollectionSnapshot(
            suggestedName: "Tokyo Trip",
            suggestedIcon: "airplane",
            places: [SharedPlaceIdentity(appleMapIdentifier: "a", name: "Ichiran", latitude: 35.66, longitude: 139.70)]
        )

        let result = service.importAsNewCollection(snapshot)

        #expect(result.collection.name == "Tokyo Trip")
        #expect(result.collection.icon == "airplane")
        #expect(result.newPlaceCount == 1)
        #expect(result.alreadySavedCount == 0)
    }

    @Test func importAsNewCollectionSkipsAlreadySavedPlaces() throws {
        let context = try makeContext()
        let service = makeService(context: context)
        let existingCollection = CollectionRepository(modelContext: context).create(name: "Existing", icon: "star")
        PlaceRepository(modelContext: context).insert(
            Place(appleMapIdentifier: "a", name: "Ichiran", latitude: 35.66, longitude: 139.70, collection: existingCollection)
        )

        let snapshot = SharedCollectionSnapshot(
            suggestedName: "Tokyo Trip",
            suggestedIcon: "airplane",
            places: [
                SharedPlaceIdentity(appleMapIdentifier: "a", name: "Ichiran", latitude: 35.66, longitude: 139.70),
                SharedPlaceIdentity(appleMapIdentifier: "b", name: "Sushi Dai", latitude: 35.66, longitude: 139.77)
            ]
        )

        let result = service.importAsNewCollection(snapshot)

        #expect(result.newPlaceCount == 1)
        #expect(result.alreadySavedCount == 1)
    }

    @Test func mergeIntoExistingCollectionPreservesNameIconAndOnlyAddsNewPlaces() throws {
        let context = try makeContext()
        let service = makeService(context: context)
        let destination = CollectionRepository(modelContext: context).create(name: "My Japan List", icon: "star")

        let snapshot = SharedCollectionSnapshot(
            suggestedName: "Tokyo Trip",
            suggestedIcon: "airplane",
            places: [SharedPlaceIdentity(appleMapIdentifier: "a", name: "Ichiran", latitude: 35.66, longitude: 139.70)]
        )

        let result = service.mergeIntoExistingCollection(snapshot, destination: destination)

        #expect(result.collection.id == destination.id)
        #expect(result.collection.name == "My Japan List")
        #expect(result.collection.icon == "star")
        #expect(result.newPlaceCount == 1)
    }

    @Test func emptySnapshotProducesZeroCounts() throws {
        let context = try makeContext()
        let service = makeService(context: context)
        let snapshot = SharedCollectionSnapshot(suggestedName: "Empty", suggestedIcon: "tray", places: [])

        let result = service.importAsNewCollection(snapshot)

        #expect(result.newPlaceCount == 0)
        #expect(result.alreadySavedCount == 0)
    }
}
