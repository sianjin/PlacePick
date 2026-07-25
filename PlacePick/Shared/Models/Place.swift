import Foundation
import SwiftData

/// Long-term relationship data only. Emotion and Note moved to Visit — see DATA_MODEL.md
/// §5: "The same Place may have different Emotions across different Visits."
@Model
final class Place {
    var id: UUID = UUID()

    var appleMapIdentifier: String?
    var name: String = ""
    var latitude: Double = 0
    var longitude: Double = 0

    /// Optional only for CloudKit sync compatibility (SwiftData requires every
    /// relationship to be optional) — a Place without a Collection is not a valid app
    /// state; every call site still treats this as required and must resolve it.
    var collection: PlaceCollection?
    var isFavorite: Bool = false

    var createdAt: Date = Date.now
    var modifiedAt: Date = Date.now
    var deletedAt: Date?

    /// Inverse of Visit.place — required by CloudKit ("all relationships must have an
    /// inverse"). Application code queries Visits by Place via VisitRepository, not
    /// through this array.
    @Relationship(inverse: \Visit.place) var visits: [Visit]? = []

    init(
        id: UUID = UUID(),
        appleMapIdentifier: String?,
        name: String,
        latitude: Double,
        longitude: Double,
        collection: PlaceCollection,
        isFavorite: Bool = false,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.appleMapIdentifier = appleMapIdentifier
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.collection = collection
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deletedAt = deletedAt
    }
}

extension Place {
    /// Only enough to identify the Place — never Collection, Favorite, Emotion, Note,
    /// or Memory Photo. See DATA_MODEL.md "Shared Place Identity".
    var sharedIdentity: SharedPlaceIdentity {
        SharedPlaceIdentity(
            appleMapIdentifier: appleMapIdentifier,
            name: name,
            latitude: latitude,
            longitude: longitude
        )
    }

    /// Every Place has a Collection in normal app usage; `collection` is only Optional
    /// for CloudKit's relationship requirement. This is the display fallback for the rare
    /// transient-sync-nil case, never expected to be seen in practice.
    var displayIcon: String {
        collection?.icon ?? "mappin.circle"
    }
}
