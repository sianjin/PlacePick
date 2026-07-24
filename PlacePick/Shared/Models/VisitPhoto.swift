import Foundation
import SwiftData

/// One Photo attached to one Visit. See DATA_MODEL.md §8. Schema only in this pass —
/// nothing creates or displays VisitPhotos yet; Photo-first import is a later step.
@Model
final class VisitPhoto {
    @Attribute(.unique) var id: UUID

    var visit: Visit
    var localAssetIdentifier: String?
    var storedImageReference: String
    var capturedAt: Date
    var latitude: Double?
    var longitude: Double?
    var sortOrder: Int

    var createdAt: Date
    var modifiedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        visit: Visit,
        localAssetIdentifier: String? = nil,
        storedImageReference: String,
        capturedAt: Date,
        latitude: Double? = nil,
        longitude: Double? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.visit = visit
        self.localAssetIdentifier = localAssetIdentifier
        self.storedImageReference = storedImageReference
        self.capturedAt = capturedAt
        self.latitude = latitude
        self.longitude = longitude
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deletedAt = deletedAt
    }
}
