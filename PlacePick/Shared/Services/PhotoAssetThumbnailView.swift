import SwiftUI
import Photos

/// Resolves a Photos-library asset identifier to a thumbnail, via PHImageManager, backed
/// by a small bounded cache (PhotoThumbnailCache) for scroll performance. Never stores a
/// permanent copy — PlacePick is a personal memory layer over the user's own Photos
/// library, not a photo container. Falls back to a neutral icon when the identifier is
/// missing or the asset can no longer be resolved (e.g. deleted from Photos).
struct PhotoAssetThumbnailView: View {
    let localAssetIdentifier: String?
    let fallbackIcon: String

    @State private var thumbnail: UIImage?
    @State private var didAttemptLoad = false

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color(.secondarySystemBackground))
                Image(systemName: fallbackIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
            }
        }
        .clipped()
        .task(id: localAssetIdentifier) {
            guard !didAttemptLoad else { return }
            didAttemptLoad = true
            await load()
        }
    }

    private func load() async {
        guard let localAssetIdentifier else { return }

        if let cached = PhotoThumbnailCache.shared.image(for: localAssetIdentifier) {
            thumbnail = cached
            return
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localAssetIdentifier], options: nil)
        guard let asset = assets.firstObject else { return }

        if let image = await Self.requestImage(for: asset) {
            PhotoThumbnailCache.shared.store(image, for: localAssetIdentifier)
            thumbnail = image
        }
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
