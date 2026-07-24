import Foundation
import SwiftData

/// Long-term relationship data only. Emotion and Note moved to Visit — see DATA_MODEL.md
/// §5: "The same Place may have different Emotions across different Visits."
@Model
final class Place {
    @Attribute(.unique) var id: UUID

    var appleMapIdentifier: String?
    var name: String
    var latitude: Double
    var longitude: Double

    var collection: PlaceCollection
    var isFavorite: Bool

    var createdAt: Date
    var modifiedAt: Date
    var deletedAt: Date?

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
}
