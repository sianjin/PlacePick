import Foundation
import SwiftData

/// This pass supports at most one active Visit per Place — a compatibility shim so
/// existing single-relationship UI (PlaceDetailSheet, PersonalInfoForm) can read/write
/// Emotion and Note without a Memories list. Multi-Visit UI is a later step; the schema
/// itself does not enforce this limit. See DATA_MODEL.md §7.
@MainActor
final class VisitRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func findActiveVisit(for place: Place) -> Visit? {
        let placeID = place.id
        let descriptor = FetchDescriptor<Visit>(
            predicate: #Predicate { $0.place.id == placeID && $0.deletedAt == nil }
        )
        return (try? modelContext.fetch(descriptor))?.first
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
}
