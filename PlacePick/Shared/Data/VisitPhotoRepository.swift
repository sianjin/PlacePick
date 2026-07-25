import Foundation
import SwiftData

@MainActor
final class VisitPhotoRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchPhotos(for visit: Visit) -> [VisitPhoto] {
        let visitID = visit.id
        let descriptor = FetchDescriptor<VisitPhoto>(
            predicate: #Predicate { $0.visit?.id == visitID && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Attaches PhotoImportCandidates to a Visit as VisitPhotos, then recomputes the
    /// Visit's startedAt/endedAt from every attached Photo's actual capture time — see
    /// DATA_MODEL.md §7.2: "the earliest/latest reliable capture time among the Visit's
    /// Photos," never when the user happened to attach them in PlacePick.
    @discardableResult
    func attach(_ candidates: [PhotoImportCandidate], to visit: Visit) -> [VisitPhoto] {
        let existingCount = fetchPhotos(for: visit).count

        var inserted: [VisitPhoto] = []
        for (index, candidate) in candidates.enumerated() {
            let visitPhoto = VisitPhoto(
                visit: visit,
                localAssetIdentifier: candidate.localAssetIdentifier,
                storedImageReference: candidate.localAssetIdentifier,
                capturedAt: candidate.capturedAt,
                latitude: candidate.latitude,
                longitude: candidate.longitude,
                sortOrder: existingCount + index
            )
            modelContext.insert(visitPhoto)
            inserted.append(visitPhoto)
        }

        let allCapturedDates = fetchPhotos(for: visit).map(\.capturedAt) + candidates.map(\.capturedAt)
        if let earliest = allCapturedDates.min(), let latest = allCapturedDates.max() {
            visit.startedAt = earliest
            visit.endedAt = latest
            visit.modifiedAt = .now
        }

        try? modelContext.save()
        return inserted
    }

    /// Removes one Photo from its Visit — DATA_MODEL.md §22.3. Callers must decide what to
    /// do when this is the Visit's last active Photo (an active Visit cannot persist with
    /// zero Photos); this method does not enforce that itself.
    func softDelete(_ photo: VisitPhoto) {
        photo.deletedAt = .now
        photo.modifiedAt = .now
        try? modelContext.save()
    }
}
