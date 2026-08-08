import UIKit
import Photos

/// Saves a rendered Day Detail snapshot to the user's Photos library — the trimmed,
/// nav-bar-free alternative to a raw iOS screenshot (which always includes the status bar
/// and can't be avoided; see DayScreenshotPrompt). Reuses the same .readWrite Photos
/// authorization MomentMap already requests for reading photo metadata.
enum DaySnapshotSaver {
    enum SaveError: Error {
        case authorizationDenied
    }

    static func save(_ image: UIImage) async throws {
        let status = await PhotoLibraryService.requestReadAccessIfNeeded()
        guard status == .authorized || status == .limited else {
            throw SaveError.authorizationDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
