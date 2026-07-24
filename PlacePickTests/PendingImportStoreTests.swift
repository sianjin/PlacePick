import Testing
import Foundation
@testable import PlacePick

struct PendingImportStoreTests {
    @Test func savedPendingImportCanBeLoadedBack() {
        let pending = PendingImport(sharedTitle: "Blue Bottle Coffee", suggestedSearchText: "Blue Bottle Coffee")
        PendingImportStore.save(pending)
        defer { PendingImportStore.clear() }

        let loaded = PendingImportStore.load()
        #expect(loaded?.id == pending.id)
        #expect(loaded?.suggestedSearchText == "Blue Bottle Coffee")
    }

    @Test func clearRemovesThePendingImport() {
        PendingImportStore.save(PendingImport(suggestedSearchText: "Ramen Nagi"))
        PendingImportStore.clear()

        #expect(PendingImportStore.load() == nil)
    }

    @Test func expiredPendingImportIsDiscardedOnLoad() {
        let stale = PendingImport(suggestedSearchText: "Old Search", createdAt: .now.addingTimeInterval(-15 * 60))
        PendingImportStore.save(stale)
        defer { PendingImportStore.clear() }

        #expect(PendingImportStore.load() == nil)
    }

    @Test func savedSharedPlaceIdentityRoundTrips() {
        let identity = SharedPlaceIdentity(appleMapIdentifier: "a", name: "Ichiran", latitude: 35.66, longitude: 139.70)
        PendingImportStore.save(PendingImport(sharedPlaceIdentity: identity))
        defer { PendingImportStore.clear() }

        #expect(PendingImportStore.load()?.sharedPlaceIdentity == identity)
    }

    @Test func savedSharedCollectionSnapshotRoundTrips() {
        let snapshot = SharedCollectionSnapshot(
            suggestedName: "Tokyo Trip",
            suggestedIcon: "airplane",
            places: [SharedPlaceIdentity(appleMapIdentifier: "a", name: "Ichiran", latitude: 35.66, longitude: 139.70)]
        )
        PendingImportStore.save(PendingImport(sharedCollectionSnapshot: snapshot))
        defer { PendingImportStore.clear() }

        #expect(PendingImportStore.load()?.sharedCollectionSnapshot == snapshot)
    }
}
