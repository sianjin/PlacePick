import Foundation
import Combine

/// Bridges the placepick://import hand-off to the Map workspace. Holds at most one pending
/// import at a time; the Share Extension only ever creates one before opening the app.
/// See IMPORT_PIPELINE.md "Import Boundary" — import ends at Identity resolution, after
/// which the standard Capture Flow (AddPlaceScreen) takes over unmodified.
@MainActor
final class PendingImportCoordinator: ObservableObject {
    @Published var pendingImport: PendingImport?

    func handleOpenURL(_ url: URL) {
        guard url.scheme == "placepick", url.host == "import" else { return }
        pendingImport = PendingImportStore.load()
    }

    func consumePendingImport() -> PendingImport? {
        defer {
            pendingImport = nil
            PendingImportStore.clear()
        }
        return pendingImport
    }
}
