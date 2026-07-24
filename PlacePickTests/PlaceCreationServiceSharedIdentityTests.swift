import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct PlaceCreationServiceSharedIdentityTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func createsNewPlaceFromSharedIdentity() throws {
        let context = try makeContext()
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let service = PlaceCreationService(repository: PlaceRepository(modelContext: context))
        let identity = SharedPlaceIdentity(appleMapIdentifier: "apple-1", name: "Ichiran", latitude: 35.66, longitude: 139.70)

        let result = service.createPlace(from: identity, collection: collection)

        guard case .created(let place) = result else {
            Issue.record("Expected .created")
            return
        }
        #expect(place.name == "Ichiran")
        #expect(place.appleMapIdentifier == "apple-1")
        #expect(place.isFavorite == false)
    }

    @Test func returnsExistingWhenAppleMapIdentifierMatches() throws {
        let context = try makeContext()
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let service = PlaceCreationService(repository: PlaceRepository(modelContext: context))
        let identity = SharedPlaceIdentity(appleMapIdentifier: "apple-1", name: "Ichiran", latitude: 35.66, longitude: 139.70)
        guard case .created(let first) = service.createPlace(from: identity, collection: collection) else {
            Issue.record("Expected first call to create")
            return
        }

        let result = service.createPlace(from: identity, collection: collection)

        guard case .existing(let existing) = result else {
            Issue.record("Expected .existing")
            return
        }
        #expect(existing.id == first.id)
    }

    @Test func returnsExistingWhenNearbyNameMatchesWithoutIdentifier() throws {
        let context = try makeContext()
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let service = PlaceCreationService(repository: PlaceRepository(modelContext: context))
        let original = SharedPlaceIdentity(appleMapIdentifier: nil, name: "Sogo Tofu", latitude: 37.55, longitude: -122.01)
        guard case .created(let first) = service.createPlace(from: original, collection: collection) else {
            Issue.record("Expected first call to create")
            return
        }

        let duplicate = SharedPlaceIdentity(appleMapIdentifier: nil, name: "Sogo Tofu", latitude: 37.55001, longitude: -122.01001)
        let result = service.createPlace(from: duplicate, collection: collection)

        guard case .existing(let existing) = result else {
            Issue.record("Expected .existing")
            return
        }
        #expect(existing.id == first.id)
    }

    @Test func createsSeparatePlaceWhenNameMatchesButFar() throws {
        let context = try makeContext()
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let service = PlaceCreationService(repository: PlaceRepository(modelContext: context))
        let sanFrancisco = SharedPlaceIdentity(appleMapIdentifier: nil, name: "Starbucks", latitude: 37.7749, longitude: -122.4194)
        _ = service.createPlace(from: sanFrancisco, collection: collection)

        let newYork = SharedPlaceIdentity(appleMapIdentifier: nil, name: "Starbucks", latitude: 40.7128, longitude: -74.0060)
        let result = service.createPlace(from: newYork, collection: collection)

        guard case .created = result else {
            Issue.record("Expected a separate Place far away with the same name to be created")
            return
        }
    }
}
