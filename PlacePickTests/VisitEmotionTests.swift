import Testing
import Foundation
import SwiftData
@testable import PlacePick

struct VisitEmotionTests {
    let testCollection = PlaceCollection(name: "Test Collection", icon: "mappin", order: 0)

    private func makePlace() -> Place {
        Place(appleMapIdentifier: "id", name: "Test Place", latitude: 0, longitude: 0, collection: testCollection)
    }

    @Test func newVisitDefaultsToNilEmotion() {
        let visit = Visit(place: makePlace())

        #expect(visit.emotion == nil)
    }

    @Test func nilAndNeutralAreDistinctValues() {
        let unresolved = Visit(place: makePlace(), emotion: nil)
        let neutral = Visit(place: makePlace(), emotion: .neutral)

        #expect(unresolved.emotion != neutral.emotion)
    }

    @Test func savingAndReloadingPreservesNilEmotion() throws {
        let schema = Schema([Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let collection = PlaceCollection(name: "Test Collection", icon: "mappin", order: 0)
        context.insert(collection)
        let place = Place(appleMapIdentifier: "id", name: "Place", latitude: 0, longitude: 0, collection: collection)
        context.insert(place)
        let visit = Visit(place: place)
        context.insert(visit)
        try context.save()

        let id = visit.id
        let descriptor = FetchDescriptor<Visit>(predicate: #Predicate { $0.id == id })
        let reloaded = try context.fetch(descriptor).first

        #expect(reloaded?.emotion == nil)
    }

    @Test func clearingEmotionRestoresNil() {
        let visit = Visit(place: makePlace(), emotion: .happy)
        visit.emotion = nil

        #expect(visit.emotion == nil)
    }
}
