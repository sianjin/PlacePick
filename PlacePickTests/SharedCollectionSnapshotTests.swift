import Testing
import Foundation
@testable import PlacePick

struct SharedCollectionSnapshotTests {
    @Test func snapshotRoundTripsThroughJSON() throws {
        let snapshot = SharedCollectionSnapshot(
            suggestedName: "Tokyo Trip",
            suggestedIcon: "airplane",
            places: [
                SharedPlaceIdentity(appleMapIdentifier: "apple-1", name: "Ichiran", latitude: 35.66, longitude: 139.70),
                SharedPlaceIdentity(appleMapIdentifier: nil, name: "Unnamed Spot", latitude: 1, longitude: 2)
            ]
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(SharedCollectionSnapshot.self, from: data)

        #expect(decoded == snapshot)
    }
}
