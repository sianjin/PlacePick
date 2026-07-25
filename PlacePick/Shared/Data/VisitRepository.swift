import Foundation
import SwiftData

/// A Place may have many Visits (Memories) — see fetchVisits(for:) and DATA_MODEL.md §7,
/// §20. findActiveVisit/findOrCreateActiveVisit return a single Visit for call sites that
/// only ever need "a" Visit to attach to (e.g. seeding one at Place creation); they are not
/// a limit on how many Visits a Place can have.
@MainActor
final class VisitRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func findActiveVisit(for place: Place) -> Visit? {
        let placeID = place.id
        let descriptor = FetchDescriptor<Visit>(
            predicate: #Predicate { $0.place?.id == placeID && $0.deletedAt == nil }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    /// All active Visits (Memories) for a Place, most recent first — DATA_MODEL.md §20
    /// Place Detail Projection. A Place may have many Visits; this is the full list, not
    /// the single-Visit compatibility shim used elsewhere in this file.
    func fetchVisits(for place: Place) -> [Visit] {
        let placeID = place.id
        let descriptor = FetchDescriptor<Visit>(
            predicate: #Predicate { $0.place?.id == placeID && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Returns the Place's existing Visit, or creates a blank one. Used wherever the UI
    /// needs a Visit to read/write Emotion or Note against but the user hasn't necessarily
    /// recorded either yet.
    @discardableResult
    func findOrCreateActiveVisit(for place: Place) -> Visit {
        if let existing = findActiveVisit(for: place) {
            return existing
        }
        let visit = Visit(place: place)
        modelContext.insert(visit)
        try? modelContext.save()
        return visit
    }

    func fetchAllActive() -> [Visit] {
        let descriptor = FetchDescriptor<Visit>(predicate: #Predicate { $0.deletedAt == nil })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Visits whose startedAt falls on the given local calendar day. See DATA_MODEL.md
    /// §19.2 — Calendar groups by local day and never creates duplicate records.
    func fetchVisits(on day: Date, calendar: Calendar = .current) -> [Visit] {
        let dayInterval = calendar.dateInterval(of: .day, for: day)
        return fetchAllActive()
            .filter { visit in
                guard let dayInterval else { return false }
                return dayInterval.contains(visit.startedAt)
            }
            .sorted { $0.startedAt < $1.startedAt }
    }

    func save() {
        try? modelContext.save()
    }

    /// Deletes a Visit and cascades to its VisitPhotos — DATA_MODEL.md §22.2. Does not
    /// delete the Place.
    func softDelete(_ visit: Visit) {
        let visitPhotoRepository = VisitPhotoRepository(modelContext: modelContext)
        for photo in visitPhotoRepository.fetchPhotos(for: visit) {
            photo.deletedAt = .now
            photo.modifiedAt = .now
        }
        visit.deletedAt = .now
        visit.modifiedAt = .now
        try? modelContext.save()
    }
}
