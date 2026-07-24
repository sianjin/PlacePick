import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct VisitRepositoryTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makePlace(context: ModelContext, name: String = "Test Place") -> Place {
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let place = Place(appleMapIdentifier: "id-\(UUID())", name: name, latitude: 0, longitude: 0, collection: collection)
        context.insert(place)
        return place
    }

    @Test func fetchVisitsOnDayReturnsOnlyThatLocalDay() throws {
        let context = try makeContext()
        let repository = VisitRepository(modelContext: context)
        let calendar = Calendar.current
        let targetDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18))!

        let matching = Visit(place: makePlace(context: context, name: "Blue Bottle"), startedAt: targetDay.addingTimeInterval(9 * 3600))
        let alsoMatching = Visit(place: makePlace(context: context, name: "Ferry Building"), startedAt: targetDay.addingTimeInterval(17 * 3600))
        let differentDay = Visit(place: makePlace(context: context, name: "Golden Gate"), startedAt: targetDay.addingTimeInterval(-3600))
        context.insert(matching)
        context.insert(alsoMatching)
        context.insert(differentDay)
        try context.save()

        let result = repository.fetchVisits(on: targetDay)

        #expect(result.map(\.place.name) == ["Blue Bottle", "Ferry Building"])
    }

    @Test func fetchVisitsOnDayExcludesSoftDeletedVisits() throws {
        let context = try makeContext()
        let repository = VisitRepository(modelContext: context)
        let day = Date()

        let visit = Visit(place: makePlace(context: context), startedAt: day, deletedAt: .now)
        context.insert(visit)
        try context.save()

        #expect(repository.fetchVisits(on: day).isEmpty)
    }

    @Test func fetchVisitsOnDaySortsChronologically() throws {
        let context = try makeContext()
        let repository = VisitRepository(modelContext: context)
        let day = Calendar.current.startOfDay(for: .now)

        let later = Visit(place: makePlace(context: context, name: "Nopa"), startedAt: day.addingTimeInterval(19 * 3600))
        let earlier = Visit(place: makePlace(context: context, name: "Blue Bottle"), startedAt: day.addingTimeInterval(9 * 3600))
        context.insert(later)
        context.insert(earlier)
        try context.save()

        let result = repository.fetchVisits(on: day)

        #expect(result.map(\.place.name) == ["Blue Bottle", "Nopa"])
    }

    @Test func multipleVisitsToSamePlaceRemainSeparate() throws {
        let context = try makeContext()
        let repository = VisitRepository(modelContext: context)
        let day = Calendar.current.startOfDay(for: .now)
        let place = makePlace(context: context, name: "Blue Bottle")

        context.insert(Visit(place: place, startedAt: day.addingTimeInterval(9 * 3600)))
        context.insert(Visit(place: place, startedAt: day.addingTimeInterval(17 * 3600)))
        try context.save()

        #expect(repository.fetchVisits(on: day).count == 2)
    }

    @Test func findOrCreateActiveVisitReturnsExistingRatherThanDuplicating() throws {
        let context = try makeContext()
        let repository = VisitRepository(modelContext: context)
        let place = makePlace(context: context)

        let first = repository.findOrCreateActiveVisit(for: place)
        let second = repository.findOrCreateActiveVisit(for: place)

        #expect(first.id == second.id)
    }
}
