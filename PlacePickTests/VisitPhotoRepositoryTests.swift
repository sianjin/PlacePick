import Testing
import Foundation
import SwiftData
@testable import PlacePick

@MainActor
struct VisitPhotoRepositoryTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makeVisit(context: ModelContext) -> Visit {
        let collection = CollectionRepository(modelContext: context).create(name: "Food", icon: "fork.knife")
        let place = Place(appleMapIdentifier: "id", name: "Test Place", latitude: 0, longitude: 0, collection: collection)
        context.insert(place)
        let visit = Visit(place: place)
        context.insert(visit)
        return visit
    }

    @Test func fetchPhotosReturnsInSortOrder() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)

        context.insert(VisitPhoto(visit: visit, storedImageReference: "b", capturedAt: .now, sortOrder: 1))
        context.insert(VisitPhoto(visit: visit, storedImageReference: "a", capturedAt: .now, sortOrder: 0))
        try context.save()

        let result = repository.fetchPhotos(for: visit)

        #expect(result.map(\.storedImageReference) == ["a", "b"])
    }

    @Test func fetchPhotosExcludesOtherVisits() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visitA = makeVisit(context: context)
        let visitB = makeVisit(context: context)

        context.insert(VisitPhoto(visit: visitA, storedImageReference: "a", capturedAt: .now))
        context.insert(VisitPhoto(visit: visitB, storedImageReference: "b", capturedAt: .now))
        try context.save()

        let result = repository.fetchPhotos(for: visitA)

        #expect(result.map(\.storedImageReference) == ["a"])
    }

    @Test func fetchPhotosExcludesSoftDeleted() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)

        context.insert(VisitPhoto(visit: visit, storedImageReference: "a", capturedAt: .now, deletedAt: .now))
        try context.save()

        #expect(repository.fetchPhotos(for: visit).isEmpty)
    }

    @Test func visitWithNoPhotosReturnsEmpty() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)

        #expect(repository.fetchPhotos(for: visit).isEmpty)
    }

    @Test func attachingAnOldPhotoUpdatesVisitStartedAtToItsCaptureTime() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)
        let oldDate = Date(timeIntervalSince1970: 1_000_000_000) // 2001, long before "now"
        let candidate = PhotoImportCandidate(id: "a", localAssetIdentifier: "a", capturedAt: oldDate, latitude: nil, longitude: nil)

        repository.attach([candidate], to: visit)

        #expect(visit.startedAt == oldDate)
        #expect(visit.endedAt == oldDate)
    }

    @Test func attachingMultiplePhotosSpansStartedAtToEndedAt() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)
        let earlier = Date(timeIntervalSince1970: 1_000_000_000)
        let later = Date(timeIntervalSince1970: 1_000_100_000)
        let candidates = [
            PhotoImportCandidate(id: "a", localAssetIdentifier: "a", capturedAt: later, latitude: nil, longitude: nil),
            PhotoImportCandidate(id: "b", localAssetIdentifier: "b", capturedAt: earlier, latitude: nil, longitude: nil)
        ]

        repository.attach(candidates, to: visit)

        #expect(visit.startedAt == earlier)
        #expect(visit.endedAt == later)
    }

    @Test func attachingASecondBatchExpandsTheExistingRange() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)
        let firstBatchDate = Date(timeIntervalSince1970: 1_000_100_000)
        let olderPhotoAddedLater = Date(timeIntervalSince1970: 1_000_000_000)

        repository.attach([PhotoImportCandidate(id: "a", localAssetIdentifier: "a", capturedAt: firstBatchDate, latitude: nil, longitude: nil)], to: visit)
        repository.attach([PhotoImportCandidate(id: "b", localAssetIdentifier: "b", capturedAt: olderPhotoAddedLater, latitude: nil, longitude: nil)], to: visit)

        #expect(visit.startedAt == olderPhotoAddedLater)
        #expect(visit.endedAt == firstBatchDate)
    }

    @Test func attachAssignsIncreasingSortOrderAfterExistingPhotos() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)
        repository.attach([PhotoImportCandidate(id: "a", localAssetIdentifier: "a", capturedAt: .now, latitude: nil, longitude: nil)], to: visit)

        let inserted = repository.attach([PhotoImportCandidate(id: "b", localAssetIdentifier: "b", capturedAt: .now, latitude: nil, longitude: nil)], to: visit)

        #expect(inserted.first?.sortOrder == 1)
    }

    @Test func softDeleteExcludesPhotoFromFetchPhotos() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)
        let photo = VisitPhoto(visit: visit, storedImageReference: "a", capturedAt: .now)
        context.insert(photo)
        try context.save()

        repository.softDelete(photo)

        #expect(repository.fetchPhotos(for: visit).isEmpty)
        #expect(photo.deletedAt != nil)
    }

    @Test func softDeleteLeavesOtherPhotosOnTheVisitIntact() throws {
        let context = try makeContext()
        let repository = VisitPhotoRepository(modelContext: context)
        let visit = makeVisit(context: context)
        let toDelete = VisitPhoto(visit: visit, storedImageReference: "a", capturedAt: .now, sortOrder: 0)
        let toKeep = VisitPhoto(visit: visit, storedImageReference: "b", capturedAt: .now, sortOrder: 1)
        context.insert(toDelete)
        context.insert(toKeep)
        try context.save()

        repository.softDelete(toDelete)

        #expect(repository.fetchPhotos(for: visit).map(\.storedImageReference) == ["b"])
    }
}
