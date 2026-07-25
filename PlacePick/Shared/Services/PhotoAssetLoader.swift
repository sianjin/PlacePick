import UIKit
import Photos

/// Shared async PHAsset-to-UIImage resolution, backed by PhotoThumbnailCache. Used by
/// PhotoAssetThumbnailView (which needs it wrapped in a SwiftUI-friendly .task) and by
/// callers that need an already-loaded image synchronously in hand — e.g. rendering a Day
/// Detail snapshot via ImageRenderer, which reads the view tree instantly and can't wait on
/// a view's own async load. See PhotoThumbnailCache: never a permanent copy, only a bounded
/// cache over the user's own Photos library.
enum PhotoAssetLoader {
    static func loadImage(for localAssetIdentifier: String) async -> UIImage? {
        if let cached = PhotoThumbnailCache.shared.image(for: localAssetIdentifier) {
            return cached
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localAssetIdentifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        guard let image = await requestImage(for: asset) else { return nil }
        PhotoThumbnailCache.shared.store(image, for: localAssetIdentifier)
        return image
    }

    private static func requestImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            // .opportunistic can invoke the result handler twice (low-quality preview,
            // then final image); a checked continuation may only resume once, so request
            // the single high-quality delivery instead.
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 600, height: 600),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
