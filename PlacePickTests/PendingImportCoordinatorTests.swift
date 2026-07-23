import Testing
import Foundation
@testable import PlacePick

@MainActor
struct PendingImportCoordinatorTests {
    @Test func handleOpenURLIgnoresUnrelatedSchemesAndHosts() {
        let coordinator = PendingImportCoordinator()

        coordinator.handleOpenURL(URL(string: "https://example.com")!)
        #expect(coordinator.pendingImport == nil)

        coordinator.handleOpenURL(URL(string: "placepick://somethingElse")!)
        #expect(coordinator.pendingImport == nil)
    }

    @Test func handleOpenURLLoadsAWaitingPendingImport() {
        let stored = PendingImport(sharedTitle: "Blue Bottle Coffee", suggestedSearchText: "Blue Bottle Coffee")
        PendingImportStore.save(stored)
        defer { PendingImportStore.clear() }

        let coordinator = PendingImportCoordinator()
        coordinator.handleOpenURL(URL(string: "placepick://import")!)

        #expect(coordinator.pendingImport?.id == stored.id)
    }

    @Test func consumePendingImportClearsCoordinatorAndStore() {
        let stored = PendingImport(suggestedSearchText: "Ramen Nagi")
        PendingImportStore.save(stored)

        let coordinator = PendingImportCoordinator()
        coordinator.handleOpenURL(URL(string: "placepick://import")!)

        let consumed = coordinator.consumePendingImport()

        #expect(consumed?.suggestedSearchText == "Ramen Nagi")
        #expect(coordinator.pendingImport == nil)
        #expect(PendingImportStore.load() == nil)
    }

    @Test func consumingWithNoPendingImportReturnsNil() {
        let coordinator = PendingImportCoordinator()
        #expect(coordinator.consumePendingImport() == nil)
    }
}
