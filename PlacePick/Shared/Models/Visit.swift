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

/// One experience at one Place during one continuous time period. User-facing term is
/// "Memory"; persistence-layer term is "Visit" — see DATA_MODEL.md §2–3. Emotion and Note
/// belong here, not on Place, because the same Place may feel different across visits.
///
/// This pass creates at most one Visit per Place (a compatibility shim so existing
/// single-relationship UI keeps working). The model itself does not enforce that limit —
/// multi-Visit UI (Calendar, Day Detail, Photo-first import) is a later step.
@Model
final class Visit {
    @Attribute(.unique) var id: UUID

    var place: Place
    var startedAt: Date
    var endedAt: Date
    var emotion: PlaceEmotion?
    var note: String

    var createdAt: Date
    var modifiedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        place: Place,
        startedAt: Date = .now,
        endedAt: Date = .now,
        emotion: PlaceEmotion? = nil,
        note: String = "",
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.place = place
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.emotion = emotion
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deletedAt = deletedAt
    }
}
