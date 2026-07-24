import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct PlaceSharedIdentityTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func sharedIdentityCarriesOnlyIdentityFields() throws {
        let context = try makeContext()
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let place = Place(
            appleMapIdentifier: "apple-123",
            name: "Sogo Tofu",
            latitude: 37.55,
            longitude: -122.01,
            collection: collection,
            isFavorite: true,
            note: "So good"
        )

        let identity = place.sharedIdentity

        #expect(identity.appleMapIdentifier == "apple-123")
        #expect(identity.name == "Sogo Tofu")
        #expect(identity.latitude == 37.55)
        #expect(identity.longitude == -122.01)
    }
}
