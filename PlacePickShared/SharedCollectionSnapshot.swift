import Foundation
import UniformTypeIdentifiers

/// A Place Identity as it travels between users. Excludes Collection, Favorite, Emotion,
/// Note, and Memory Photo — a shared Place never contains another person's memories.
/// See DATA_MODEL.md "Shared Place Identity".
struct SharedPlaceIdentity: Codable, Equatable {
    let appleMapIdentifier: String?
    let name: String
    let latitude: Double
    let longitude: Double
}

/// A one-time, portable snapshot of a Collection. See DATA_MODEL.md "Shared Collection
/// Snapshot" and MVP.md §11.1 — transfers identity only, never ownership, synchronization,
/// or personal memory. After import, the snapshot no longer exists; only local Collections remain.
struct SharedCollectionSnapshot: Codable, Equatable {
    let snapshotID: UUID
    let suggestedName: String
    let suggestedIcon: String
    let places: [SharedPlaceIdentity]

    init(
        snapshotID: UUID = UUID(),
        suggestedName: String,
        suggestedIcon: String,
        places: [SharedPlaceIdentity]
    ) {
        self.snapshotID = snapshotID
        self.suggestedName = suggestedName
        self.suggestedIcon = suggestedIcon
        self.places = places
    }
}

extension UTType {
    static let placePickCollectionSnapshot = UTType(exportedAs: "com.sianjin.PlacePick.collection-snapshot")
    static let placePickPlaceIdentity = UTType(exportedAs: "com.sianjin.PlacePick.place-identity")
}

extension SharedPlaceIdentity: Identifiable {
    /// Not part of the wire format — SharedPlaceIdentity carries no stable ID of its own,
    /// so SwiftUI's `.sheet(item:)` needs a derived one. appleMapIdentifier already
    /// uniquely identifies the real-world Place when present.
    var id: String {
        appleMapIdentifier ?? "\(name)|\(latitude)|\(longitude)"
    }
}

extension SharedCollectionSnapshot: Identifiable {
    var id: UUID { snapshotID }
}
