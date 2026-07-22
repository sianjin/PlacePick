import Testing
import Foundation
import SwiftData
@testable import PlacePick

struct PlaceEmotionTests {
    let testCollection = PlaceCollection(name: "Test Collection", icon: "mappin", order: 0)

    @Test func newPlaceDefaultsToNilEmotion() {
        let place = Place(
            appleMapIdentifier: "id",
            name: "New Place",
            latitude: 0,
            longitude: 0,
            collection: testCollection
        )

        #expect(place.emotion == nil)
    }

    @Test func nilAndNeutralAreDistinctValues() {
        let unresolved = Place(appleMapIdentifier: "a", name: "A", latitude: 0, longitude: 0, collection: testCollection, emotion: nil)
        let neutral = Place(appleMapIdentifier: "b", name: "B", latitude: 0, longitude: 0, collection: testCollection, emotion: .neutral)

        #expect(unresolved.emotion != neutral.emotion)
    }

    @Test func savingAndReloadingPreservesNilEmotion() throws {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let collection = PlaceCollection(name: "Test Collection", icon: "mappin", order: 0)
        context.insert(collection)

        let place = Place(appleMapIdentifier: "id", name: "Place", latitude: 0, longitude: 0, collection: collection)
        context.insert(place)
        try context.save()

        let id = place.id
        let descriptor = FetchDescriptor<Place>(predicate: #Predicate { $0.id == id })
        let reloaded = try context.fetch(descriptor).first

        #expect(reloaded?.emotion == nil)
    }

    @Test func clearingEmotionRestoresNil() {
        let place = Place(appleMapIdentifier: "id", name: "Place", latitude: 0, longitude: 0, collection: testCollection, emotion: .happy)
        place.emotion = nil

        #expect(place.emotion == nil)
    }
}
