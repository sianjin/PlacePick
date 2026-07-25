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
            await load()
        }
    }

    /// Re-runs on every localAssetIdentifier change (a view instance can be reused for a
    /// different photo — e.g. a Place Detail row after its cover photo is deleted), so the
    /// stale thumbnail must be cleared up front rather than left showing until the new one
    /// resolves.
    private func load() async {
        thumbnail = nil
        guard let localAssetIdentifier else { return }
        thumbnail = await PhotoAssetLoader.loadImage(for: localAssetIdentifier)
    }
}
