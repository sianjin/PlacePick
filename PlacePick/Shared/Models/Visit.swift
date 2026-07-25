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
/// A Place may have many Visits (DATA_MODEL.md §3.2) — see VisitRepository.fetchVisits(for:).
@Model
final class Visit {
    var id: UUID = UUID()

    /// Optional only for CloudKit sync compatibility (SwiftData requires every
    /// relationship to be optional) — DATA_MODEL.md §7.2 "A Visit cannot exist without a
    /// resolved Place" remains a hard product invariant; every call site still treats this
    /// as required and must resolve it.
    var place: Place?
    var startedAt: Date = Date.now
    var endedAt: Date = Date.now
    var emotion: PlaceEmotion?
    var note: String = ""

    var createdAt: Date = Date.now
    var modifiedAt: Date = Date.now
    var deletedAt: Date?

    /// Inverse of VisitPhoto.visit — required by CloudKit ("all relationships must have an
    /// inverse"). Application code queries Photos by Visit via VisitPhotoRepository, not
    /// through this array.
    @Relationship(inverse: \VisitPhoto.visit) var photos: [VisitPhoto]? = []

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
