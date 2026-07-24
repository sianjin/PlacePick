import Foundation
import SwiftData

enum PlaceEmotion: String, Codable {
    case neutral
    case happy
    case amazed

    var symbolEmoji: String {
        switch self {
        case .neutral: return "😐"
        case .happy: return "😊"
        case .amazed: return "🤩"
        }
    }
}

@Model
final class Place {
    @Attribute(.unique) var id: UUID

    var appleMapIdentifier: String?
    var name: String
    var latitude: Double
    var longitude: Double

    var collection: PlaceCollection
    var isFavorite: Bool
    var emotion: PlaceEmotion?
    var note: String
    var memoryPhotoID: String?

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
        emotion: PlaceEmotion? = nil,
        note: String = "",
        memoryPhotoID: String? = nil,
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
        self.emotion = emotion
        self.note = note
        self.memoryPhotoID = memoryPhotoID
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
